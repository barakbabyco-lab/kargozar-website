<?php

namespace App\Services\Support;

use App\Models\SupportConversation;

class GuidedServiceFlowEngine
{
    /**
     * Run a deterministic, provider-independent service questionnaire.
     *
     * A null result means the message does not belong to a configured flow.
     */
    public function handle(string $message, ?int $conversationId): ?string
    {
        if ($conversationId === null) {
            return null;
        }

        $conversation = SupportConversation::query()->find($conversationId);
        if ($conversation === null) {
            return null;
        }

        $context = is_array($conversation->assistant_context) ? $conversation->assistant_context : [];
        $state = is_array($context['guided_flow'] ?? null) ? $context['guided_flow'] : null;
        $flows = $this->flows();

        if ($state !== null && ($state['status'] ?? null) === 'active') {
            // The controller may pass a multi-turn context string to the legacy
            // assistant. During a guided flow, only the customer's latest turn
            // is the answer to the current question.
            $latestCustomerMessage = $conversation->messages()
                ->where('sender_type', 'customer')
                ->latest('id')
                ->value('body');
            if (is_string($latestCustomerMessage) && $latestCustomerMessage !== '') {
                $message = $latestCustomerMessage;
            }

            $flow = $flows[$state['flow_key'] ?? ''] ?? null;
            if (! is_array($flow)) {
                unset($context['guided_flow']);
                $conversation->forceFill(['assistant_context' => $context])->save();
                return null;
            }

            return $this->acceptAnswer($conversation, $context, $state, $flow, $message);
        }

        $matched = $this->matchFlow($message, $flows);
        if ($matched === null) {
            return null;
        }

        if ($state !== null && ($state['status'] ?? null) === 'completed'
            && ($state['flow_key'] ?? null) === ($matched['key'] ?? null)
            && preg_match('/از اول|شروع مجدد|شروع دوباره|تکرار پرسش/u', $this->normalize($message)) !== 1) {
            return null;
        }

        $state = [
            'flow_key' => $matched['key'],
            'status' => 'active',
            'question_index' => 0,
            'answers' => $this->prefillAnswers($matched, $message),
            'started_at' => now()->toISOString(),
        ];
        $context['guided_flow'] = $state;
        $conversation->forceFill(['assistant_context' => $context])->save();

        $first = $this->nextQuestion($state, $matched);
        if ($first === null) {
            return $this->finish($conversation, $context, $state, $matched);
        }

        return trim(($matched['intro'] ?? 'برای بررسی درخواست شما چند سؤال کوتاه می‌پرسم.')."\n\n".$this->renderQuestion($first));
    }

    private function acceptAnswer(
        SupportConversation $conversation,
        array $context,
        array $state,
        array $flow,
        string $message
    ): string {
        $questions = $flow['questions'] ?? [];
        $index = (int) ($state['question_index'] ?? 0);
        $question = $questions[$index] ?? null;

        if (! is_array($question)) {
            return $this->finish($conversation, $context, $state, $flow);
        }

        $answer = $this->parseAnswer($question, $message);
        if ($answer === null) {
            return "پاسخ رو متوجه نشدم. لطفاً یکی از گزینه‌های همین سؤال رو انتخاب کنید یا اگر سؤال تشریحیه، کوتاه پاسخ بدید.\n\n".$this->renderQuestion($question);
        }

        $state['answers'][$question['key']] = $answer;
        $state['question_index'] = $index + 1;

        $next = $this->nextQuestion($state, $flow);
        if ($next === null) {
            return $this->finish($conversation, $context, $state, $flow);
        }

        $context['guided_flow'] = $state;
        $conversation->forceFill(['assistant_context' => $context])->save();

        return $this->renderQuestion($next);
    }

    private function nextQuestion(array &$state, array $flow): ?array
    {
        $questions = $flow['questions'] ?? [];
        while (isset($questions[$state['question_index']])) {
            $question = $questions[$state['question_index']];
            if (array_key_exists($question['key'] ?? '', $state['answers'] ?? [])) {
                $state['question_index']++;
                continue;
            }
            $condition = $question['when'] ?? null;
            if (is_array($condition)) {
                $actual = $state['answers'][$condition['answer_key'] ?? ''] ?? null;
                $allowed = $condition['values'] ?? [];
                if (! in_array($actual, $allowed, true)) {
                    $state['question_index']++;
                    continue;
                }
            }

            return $question;
        }

        return null;
    }

    private function finish(
        SupportConversation $conversation,
        array $context,
        array $state,
        array $flow
    ): string {
        $state['status'] = 'completed';
        $state['completed_at'] = now()->toISOString();
        $context['guided_flow'] = $state;
        $conversation->forceFill(['assistant_context' => $context])->save();

        $lines = [
            "جمع‌بندی اولیه درخواست شما: ".$flow['title'],
            '',
        ];

        foreach (($flow['questions'] ?? []) as $question) {
            $key = $question['key'] ?? '';
            if (! array_key_exists($key, $state['answers'] ?? [])) {
                continue;
            }

            $value = $state['answers'][$key];
            $label = $value;
            foreach (($question['options'] ?? []) as $option) {
                if (($option['value'] ?? null) === $value) {
                    $label = $option['label'] ?? $value;
                    break;
                }
            }
            $lines[] = '✓ '.($question['summary_label'] ?? $question['question']).' '.$label;
        }

        $lines[] = '';
        $lines[] = $flow['summary_note'] ?? 'اطلاعات اولیه ثبت شد و باید با ضوابط و اطلاعات معتبر همان خدمت تطبیق داده شود.';
        $lines[] = '';
        $lines[] = 'اگر خدمت دیگری مدنظرتونه، اسمش رو بنویسید.';

        return implode("\n", $lines);
    }


    /**
     * Preserve facts the customer already supplied in the opening message.
     * This is intentionally conservative: uncertain facts remain questions.
     */
    private function prefillAnswers(array $flow, string $message): array
    {
        $text = $this->normalize($message);
        $answers = [];

        if (($flow['key'] ?? null) === 'guild-business-license') {
            if (preg_match('/مغازه ندارم|محل کسب ندارم|محل فعالیت ندارم|هنوز محل(ی)? مشخص نکردم/u', $text) === 1) {
                $answers['premises_status'] = 'not_selected';
            } elseif (preg_match('/اجاره(ای|‌ای)?|مستاجر/u', $text) === 1) {
                $answers['premises_status'] = 'rented';
            } elseif (preg_match('/ملکی|ملک خودم|مالک(م)? هستم/u', $text) === 1) {
                $answers['premises_status'] = 'owned';
            } elseif (str_contains($text, 'سرقفلی')) {
                $answers['premises_status'] = 'business_right';
            }

            $activities = [
                'خرازی' => ['retail', 'خرازی'],
                'پوشاک' => ['retail', 'فروش پوشاک'],
                'لباس فروشی' => ['retail', 'فروش پوشاک'],
                'بوتیک' => ['retail', 'بوتیک پوشاک'],
                'سوپرمارکت' => ['retail', 'سوپرمارکت'],
                'نجاری' => ['technical', 'نجاری'],
                'تعمیر موبایل' => ['technical', 'تعمیر موبایل'],
                'آرایشگاه' => ['food_health', 'آرایشگاه'],
                'رستوران' => ['food_health', 'رستوران'],
                'تولیدی' => ['production', 'تولیدی'],
            ];
            foreach ($activities as $needle => [$group, $detail]) {
                if (str_contains($text, $needle)) {
                    $answers['activity_group'] = $group;
                    $answers['activity_detail'] = $detail;
                    break;
                }
            }

            if (preg_match('/(?:شهر|در)\s*(تهران|کرج|مشهد|اصفهان|شیراز|تبریز|قم|اهواز|رشت|اراک)/u', $text, $matches) === 1) {
                $answers['city'] = $matches[1];
            }
            if (preg_match('/شخص حقیقی|به نام خودم|به نام من/u', $text) === 1) {
                $answers['applicant_type'] = 'natural_person';
            } elseif (preg_match('/شخص حقوقی|به نام شرکت|شرکت(م)?/u', $text) === 1) {
                $answers['applicant_type'] = 'legal_person';
            }
            if (preg_match('/احکام تجارت.{0,20}(دارم|گرفتم)/u', $text) === 1) {
                $answers['trade_rules_certificate'] = 'yes';
            } elseif (preg_match('/احکام تجارت.{0,20}(ندارم|نگرفتم)/u', $text) === 1) {
                $answers['trade_rules_certificate'] = 'no';
            }
            if (preg_match('/فنی.?حرفه.?ای.{0,20}(دارم|گرفتم)/u', $text) === 1) {
                $answers['vocational_certificate'] = 'yes';
            } elseif (preg_match('/فنی.?حرفه.?ای.{0,20}(ندارم|نگرفتم)/u', $text) === 1) {
                $answers['vocational_certificate'] = 'no';
            }
        }

        return $answers;
    }

    private function renderQuestion(array $question): string
    {
        $output = (string) ($question['question'] ?? 'لطفاً پاسخ خود را وارد کنید.');
        $options = $question['options'] ?? [];
        if (($question['type'] ?? 'text') === 'choice' && is_array($options)) {
            foreach (array_values($options) as $index => $option) {
                $output .= "\n".($index + 1).') '.($option['label'] ?? '');
            }
            $output .= "\n\nشماره گزینه رو بفرستید یا عنوانش رو انتخاب کنید.";
        } else {
            $output .= "\n\nپاسخ کوتاه خودتون رو بنویسید.";
        }

        return $output;
    }

    private function parseAnswer(array $question, string $message): ?string
    {
        $value = trim($this->normalize($message));
        if ($value === '') {
            return null;
        }

        $options = $question['options'] ?? [];
        if (($question['type'] ?? 'text') === 'choice' && is_array($options)) {
            $choiceText = preg_replace('/^(گزینه|شماره|مورد)\s*/u', '', $value) ?? $value;
            $digits = $this->toEnglishDigits($choiceText);
            $wordNumbers = ['اول' => 1, 'اولی' => 1, 'یک' => 1, 'یکی' => 1, 'دوم' => 2, 'دومی' => 2, 'دو' => 2, 'سوم' => 3, 'سومی' => 3, 'سه' => 3, 'چهارم' => 4, 'چهارمی' => 4, 'چهار' => 4, 'پنجم' => 5, 'پنجمی' => 5, 'پنج' => 5, 'ششم' => 6, 'ششمی' => 6, 'شش' => 6];
            if (isset($wordNumbers[$choiceText])) {
                $digits = (string) $wordNumbers[$choiceText];
            }
            if (preg_match('/^\d+$/', $digits) === 1) {
                $option = array_values($options)[((int) $digits) - 1] ?? null;
                return is_array($option) ? (string) ($option['value'] ?? '') : null;
            }

            foreach ($options as $option) {
                if (! is_array($option)) {
                    continue;
                }
                $label = $this->normalize((string) ($option['label'] ?? ''));
                $optionValue = $this->normalize((string) ($option['value'] ?? ''));
                $aliases = array_map(fn ($alias) => $this->normalize((string) $alias), $option['aliases'] ?? []);
                if ($value === $label || $value === $optionValue || in_array($value, $aliases, true)) {
                    return (string) ($option['value'] ?? '');
                }
            }

            return null;
        }

        return mb_substr(trim($message), 0, 500, 'UTF-8');
    }

    private function matchFlow(string $message, array $flows): ?array
    {
        $text = $this->normalize($message);
        foreach ($flows as $flow) {
            foreach (($flow['aliases'] ?? []) as $alias) {
                $needle = $this->normalize((string) $alias);
                if ($needle !== '' && str_contains($text, $needle)) {
                    return $flow;
                }
            }
        }

        return null;
    }

    private function flows(): array
    {
        $path = resource_path('knowledge/guided_service_flows.json');
        if (! is_file($path)) {
            return [];
        }

        $document = json_decode((string) file_get_contents($path), true);
        if (! is_array($document) || ! is_array($document['flows'] ?? null)) {
            return [];
        }

        $flows = [];
        foreach ($document['flows'] as $flow) {
            if (is_array($flow) && is_string($flow['key'] ?? null)) {
                $flows[$flow['key']] = $flow;
            }
        }

        return $flows;
    }

    private function normalize(string $value): string
    {
        $value = mb_strtolower($value, 'UTF-8');
        $value = strtr($value, ['ي' => 'ی', 'ك' => 'ک', '‌' => ' ', 'ۀ' => 'ه', 'ة' => 'ه']);
        $value = preg_replace('/[\x{064B}-\x{065F}\x{0670}]/u', '', $value) ?? $value;
        $value = preg_replace('/\s+/u', ' ', $value) ?? $value;

        return trim($value);
    }

    private function toEnglishDigits(string $value): string
    {
        return strtr($value, [
            '۰' => '0', '۱' => '1', '۲' => '2', '۳' => '3', '۴' => '4',
            '۵' => '5', '۶' => '6', '۷' => '7', '۸' => '8', '۹' => '9',
            '٠' => '0', '١' => '1', '٢' => '2', '٣' => '3', '٤' => '4',
            '٥' => '5', '٦' => '6', '٧' => '7', '٨' => '8', '٩' => '9',
        ]);
    }
}

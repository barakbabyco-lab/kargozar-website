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

        $state = [
            'flow_key' => $matched['key'],
            'status' => 'active',
            'question_index' => 0,
            'answers' => [],
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
        $lines[] = 'اگر موردی رو اشتباه وارد کردید، همون مورد رو در پیام بعدی بنویسید تا برای بررسی اصلاحش کنیم.';

        return implode("\n", $lines);
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
            $digits = $this->toEnglishDigits($value);
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
                if ($value === $label || $value === $optionValue) {
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

<?php

namespace App\Services\Support;

class SupportAssistant
{
    /**
     * Prefer structured service knowledge and FAQs; search the public web for safe unknowns.
     * Sensitive or legally consequential questions remain routed to a human.
     */
    public function reply(string $message): string
    {
        $text = $this->normalize($message);

        foreach (config('support_assistant.missing_requirement_phrases', []) as $phrase) {
            if ($phrase !== '' && str_contains($text, $this->normalize($phrase))) {
                return (string) config('support_assistant.missing_requirement_response', config('support_assistant.fallback'));
            }
        }

        foreach (config('support_assistant.escalation_terms', []) as $term) {
            if ($term !== '' && str_contains($text, $this->normalize($term))) {
                return (string) config('support_assistant.fallback');
            }
        }

        $guildAnswer = $this->guildLicenseReply($text);
        if ($guildAnswer !== null) {
            return $guildAnswer;
        }

        $knowledgeAnswer = $this->knowledgeServiceReply($text);
        if ($knowledgeAnswer !== null) {
            return $knowledgeAnswer;
        }

        $best = null;
        $bestScore = 0.0;
        $secondScore = 0.0;

        foreach (config('support_assistant.faqs', []) as $faq) {
            $keywords = $faq['keywords'] ?? [];
            if ($keywords === []) {
                continue;
            }

            $matched = 0;
            foreach ($keywords as $keyword) {
                $needle = $this->normalize($keyword);
                if ($needle !== '' && str_contains($text, $needle)) {
                    $matched++;
                }
            }

            $score = $matched / count($keywords);
            if ($score > $bestScore) {
                $secondScore = $bestScore;
                $bestScore = $score;
                $best = $faq;
            } elseif ($score > $secondScore) {
                $secondScore = $score;
            }
        }

        $threshold = (float) config('support_assistant.confidence_threshold', 0.5);
        $margin = (float) config('support_assistant.minimum_score_margin', 0.15);

        if ($best !== null && $bestScore >= $threshold && ($bestScore - $secondScore) >= $margin) {
            $answer = (string) ($best['answer'] ?? '');
            if (($best['service_assurance'] ?? false) === true) {
                $answer = $this->appendCustomerClosing($answer);
            }

            return $answer;
        }

        $dateTimeAnswer = $this->currentDateTimeReply($text);
        if ($dateTimeAnswer !== null) {
            return $dateTimeAnswer;
        }

        $webAnswer = $this->publicWebReply($message);
        if ($webAnswer !== null) {
            return $webAnswer;
        }

        return (string) config('support_assistant.fallback');
    }

    /**
     * Return the live Tehran date/time on demand, using the Persian calendar.
     */
    private function currentDateTimeReply(string $text): ?string
    {
        $dateTimeTerms = [
            'ساعت چند', 'ساعت چنده', 'الان ساعت', 'الان چه ساعتی',
            'تاریخ امروز', 'تاریخ و ساعت', 'امروز چندمه', 'امروز چه روز',
            'امروز چند شنبه', 'چه روزیه', 'الان چندمه',
            'time now', 'current date', 'what time is it',
        ];
        $asksDateTime = false;
        foreach ($dateTimeTerms as $term) {
            if (str_contains($text, $term)) {
                $asksDateTime = true;
                break;
            }
        }
        if (! $asksDateTime) {
            return null;
        }

        $now = now((string) config('support_assistant.timezone', 'Asia/Tehran'));
        $gy = (int) $now->format('Y');
        $gm = (int) $now->format('n');
        $gd = (int) $now->format('j');
        $gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
        $gy2 = $gm > 2 ? $gy + 1 : $gy;
        $days = 355666 + (365 * $gy) + intdiv($gy2 + 3, 4) - intdiv($gy2 + 99, 100)
            + intdiv($gy2 + 399, 400) + $gd + $gdm[$gm - 1];
        $jy = -1595 + (33 * intdiv($days, 12053));
        $days %= 12053;
        $jy += 4 * intdiv($days, 1461);
        $days %= 1461;
        if ($days > 365) {
            $jy += intdiv($days - 1, 365);
            $days = ($days - 1) % 365;
        }
        if ($days < 186) {
            $jm = 1 + intdiv($days, 31);
            $jd = 1 + ($days % 31);
        } else {
            $jm = 7 + intdiv($days - 186, 30);
            $jd = 1 + (($days - 186) % 30);
        }

        $months = [1 => 'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'];
        $weekdays = ['یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه'];
        $date = $weekdays[(int) $now->format('w')].'، '.$jd.' '.$months[$jm].' '.$jy;
        $time = $now->format('H:i:s');
        $digits = ['0' => '۰', '1' => '۱', '2' => '۲', '3' => '۳', '4' => '۴', '5' => '۵', '6' => '۶', '7' => '۷', '8' => '۸', '9' => '۹'];
        $date = strtr($date, $digits);
        $time = strtr($time, $digits);

        return 'تاریخ و ساعت فعلی تهران: '.$date.'، ساعت '.$time.' (منطقه زمانی Asia/Tehran).';
    }

    /**
     * Use public web search only after the internal service registry and FAQ miss.
     * Sensitive questions are intercepted earlier and never reach this method.
     */
    private function publicWebReply(string $question): ?string
    {
        if (! (bool) config('support_assistant.web_search.enabled', true)) {
            return null;
        }

        if ((string) config('support_assistant.web_search.api_key', '') === '') {
            return null;
        }

        $result = app(WebSearchService::class)->search($question);
        if (! is_array($result)) {
            return (string) config('support_assistant.web_search.no_result', '') ?: null;
        }

        $answer = trim((string) ($result['answer'] ?? ''));
        if ($answer === '') {
            $answer = 'چند منبع مرتبط پیدا شد، اما خلاصه قابل اتکایی از آن‌ها به دست نیامد. لینک منابع را برای بررسی بیشتر می‌گذارم.';
        }

        $response = (string) config('support_assistant.web_search.fallback_intro', '')."\n\n".$answer;
        $sources = $result['sources'] ?? [];
        if (is_array($sources) && $sources !== []) {
            $response .= "\n\nمنابع برای بررسی بیشتر:";
            foreach ($sources as $index => $source) {
                $title = trim((string) ($source['title'] ?? 'منبع وب'));
                $url = trim((string) ($source['url'] ?? ''));
                if ($url !== '') {
                    $response .= "\n".($index + 1).'. '.$title.' — '.$url;
                }
            }
        }

        return $response;
    }

    /**
     * Answer common guild-license document questions using the shared checklist
     * plus the activity classifier. This is a preflight, not a universal legal list.
     */
    private function guildLicenseReply(string $text): ?string
    {
        $guildTerms = ['جواز کسب', 'پروانه کسب', 'مجوز صنفی', 'مجوز کسب'];
        $isGuildQuestion = false;
        foreach ($guildTerms as $term) {
            if (str_contains($text, $this->normalize($term))) {
                $isGuildQuestion = true;
                break;
            }
        }

        if (! $isGuildQuestion || preg_match('/مدرک|مدارک|شرط|شرایط|لازم|نیاز|پیش نیاز/u', $text) !== 1) {
            return null;
        }

        $classification = $this->classifyGuildActivity($text);
        $labels = $this->requirementDisplayLabels();
        $commonKeys = $classification['common_preflight'] ?? [];
        $specialKeys = $classification['requirements'] ?? [];
        $commonLabels = [];
        $specialLabels = [];

        foreach ($commonKeys as $key) {
            $label = $labels[$key] ?? config('support_assistant.customer_communication.document_labels.'.$key);
            if (is_string($label) && $label !== '') {
                $commonLabels[] = $label;
            }
        }
        foreach ($specialKeys as $key) {
            $label = $labels[$key] ?? config('support_assistant.customer_communication.document_labels.'.$key);
            if (is_string($label) && $label !== '') {
                $specialLabels[] = $label;
            }
        }

        $answer = "برای جواز کسب، اول این موارد رو به‌عنوان چک‌لیست اولیه بررسی می‌کنیم:\n";
        if ($commonLabels !== []) {
            $answer .= $this->formatItems(array_values(array_unique($commonLabels)));
        }

        if ($specialLabels !== []) {
            $answer .= "\n\nبا توجه به نوع شغل، این موارد تخصصی هم ممکنه لازم باشه:\n";
            $answer .= $this->formatItems(array_values(array_unique($specialLabels)));
        } elseif (($classification['needs_clarification'] ?? true) === true) {
            $answer .= "\n\nبرای مشخص‌کردن مدارک تخصصی، لطفاً نوع دقیق شغل و شهر محل فعالیت رو هم بفرمایید.";
        }

        $answer .= "\n\nاین فهرست برای بررسی اولیه‌ست؛ شمول قطعی هر مورد با کاربرگ همان رسته و شرایط متقاضی تطبیق داده می‌شه.";
        return $this->appendCustomerClosing($answer);
    }

    private function requirementDisplayLabels(): array
    {
        $path = resource_path('knowledge/shared_requirement_library.json');
        if (! is_file($path)) {
            return [];
        }

        $library = json_decode((string) file_get_contents($path), true);
        if (! is_array($library) || ! is_array($library['requirements'] ?? null)) {
            return [];
        }

        $labels = [];
        foreach ($library['requirements'] as $requirement) {
            $key = $requirement['requirement_key'] ?? null;
            $label = $requirement['customer_display_label'] ?? null;
            if (is_string($key) && is_string($label) && $label !== '') {
                $labels[$key] = $label;
            }
        }

        return $labels;
    }

    /**
     * Resolve a service against the registry and its category knowledge file.
     * This provides a concise first-pass answer from existing structured records.
     */
    private function knowledgeServiceReply(string $text): ?string
    {
        $registryPath = resource_path('knowledge/service_knowledge_registry.json');
        if (! is_file($registryPath)) {
            return null;
        }

        $registry = json_decode((string) file_get_contents($registryPath), true);
        if (! is_array($registry) || ! is_array($registry['categories'] ?? null)) {
            return null;
        }

        $best = null;
        $bestScore = 0;
        $secondScore = 0;

        foreach ($registry['categories'] as $category) {
            $file = $category['knowledge_file'] ?? null;
            if (! is_string($file) || $file === '') {
                continue;
            }

            $categoryPath = resource_path('knowledge/'.$file);
            if (! is_file($categoryPath)) {
                continue;
            }

            $knowledge = json_decode((string) file_get_contents($categoryPath), true);
            if (! is_array($knowledge) || ! is_array($knowledge['services'] ?? null)) {
                continue;
            }

            foreach (($category['services'] ?? []) as $registeredService) {
                $key = $registeredService['service_key'] ?? null;
                if (! is_string($key)) {
                    continue;
                }

                $record = null;
                foreach ($knowledge['services'] as $candidate) {
                    if (($candidate['service_key'] ?? null) === $key) {
                        $record = $candidate;
                        break;
                    }
                }
                if (! is_array($record)) {
                    continue;
                }

                $title = $this->normalize((string) ($record['title'] ?? $registeredService['title'] ?? ''));
                $tokens = preg_split('/\s+/u', $title, -1, PREG_SPLIT_NO_EMPTY) ?: [];
                $stopWords = ['و', 'در', 'از', 'به', 'با', 'برای', 'یا', 'بر', 'را', 'آن'];
                $tokens = array_values(array_unique(array_filter(
                    $tokens,
                    fn ($token) => ! in_array($token, $stopWords, true) && mb_strlen($token, 'UTF-8') >= 2
                )));

                $matchedTokens = array_filter($tokens, fn ($token) => str_contains($text, $token));
                $score = count($matchedTokens);
                foreach ($tokens as $index => $token) {
                    $next = $tokens[$index + 1] ?? null;
                    if ($next !== null && str_contains($text, $token.' '.$next)) {
                        $score += 2;
                    }
                }

                // A single distinctive service name such as «اینماد» can identify a record.
                if ($score === 1 && count($tokens) === 1 && mb_strlen($tokens[0], 'UTF-8') >= 4) {
                    $score = 2;
                }

                if ($score > $bestScore) {
                    $secondScore = $bestScore;
                    $bestScore = $score;
                    $best = $record;
                } elseif ($score > $secondScore) {
                    $secondScore = $score;
                }
            }
        }

        if (! is_array($best) || $bestScore < 2 || ($bestScore - $secondScore) < 1) {
            return null;
        }

        $answer = 'برای «'.($best['title'] ?? 'این خدمت').'»، راهنمای اولیه کارگزار به این صورته:';
        $lowerText = $text;

        if (str_contains($lowerText, 'مدرک') || str_contains($lowerText, 'مدارک')) {
            $items = $this->firstItems($best['documents'] ?? [], 5);
            if ($items !== []) {
                $answer .= "\n\nمدارک قابل بررسی:\n".$this->formatItems($items);
            }
        } elseif (str_contains($lowerText, 'مرحله') || str_contains($lowerText, 'مراحل') || str_contains($lowerText, 'چطور')) {
            $items = $this->firstItems($best['steps'] ?? [], 5);
            if ($items !== []) {
                $answer .= "\n\nمراحل کلی:\n".$this->formatItems($items);
            }
        } elseif (str_contains($lowerText, 'شرط') || str_contains($lowerText, 'شرایط')) {
            $items = $this->firstItems($best['conditions'] ?? [], 5);
            if ($items !== []) {
                $answer .= "\n\nشرایط اولیه:\n".$this->formatItems($items);
            }
        } else {
            $summary = $best['what_is_it'] ?? $best['scope'] ?? $best['eligibility'] ?? null;
            if (is_string($summary) && trim($summary) !== '') {
                $answer .= "\n\n".$summary;
            }
            $items = $this->firstItems($best['conditions'] ?? [], 3);
            if ($items !== []) {
                $answer .= "\n\nمواردی که معمولاً بررسی می‌شن:\n".$this->formatItems($items);
            }
        }

        $verification = (string) ($best['verification_status'] ?? 'needs_review');
        if ($verification !== 'verified_current') {
            $answer .= "\n\nاین راهنمای اولیه‌ست؛ جزئیات نهایی باید با شرایط پرونده و آخرین ضوابط مرجع مربوط بررسی بشه.";
        }

        return $this->appendCustomerClosing($answer);
    }

    private function appendCustomerClosing(string $answer): string
    {
        $closing = (string) config(
            'support_assistant.customer_communication.standard_closing_text',
            config('support_assistant.service_assurance_closing', '')
        );

        if ($closing !== '' && ! str_contains($answer, $closing)) {
            return rtrim($answer)."\n\n".$closing;
        }

        return $answer;
    }

    private function firstItems(mixed $items, int $limit): array
    {
        if (! is_array($items)) {
            return is_string($items) && trim($items) !== '' ? [trim($items)] : [];
        }

        $items = array_values(array_filter($items, fn ($item) => is_string($item) && trim($item) !== ''));
        return array_slice($items, 0, $limit);
    }

    private function formatItems(array $items): string
    {
        $lines = [];
        foreach ($items as $index => $item) {
            $lines[] = ($index + 1).'. '.trim($item);
        }

        return implode("\n", $lines);
    }

    /**
     * Classify a guild activity into one or more specialist requirement groups.
     * The official worksheet for the exact activity remains authoritative.
     *
     * @return array{common_preflight: array, groups: array, requirements: array, needs_clarification: bool, default_only: bool, official_worksheet_overrides_classifier: bool}
     */
    public function classifyGuildActivity(string $activity): array
    {
        $text = $this->normalize($activity);
        $rules = config('support_assistant.guild_job_classification', []);
        $matchedGroups = [];
        $requirements = [];

        foreach (($rules['groups'] ?? []) as $groupKey => $group) {
            $matchedKeywords = [];
            foreach (($group['keywords'] ?? []) as $keyword) {
                $needle = $this->normalize($keyword);
                if ($needle !== '' && str_contains($text, $needle)) {
                    $matchedKeywords[] = $keyword;
                }
            }

            foreach (($group['exclude_if_only'] ?? []) as $excluded) {
                $excludedNeedle = $this->normalize($excluded);
                if ($excludedNeedle !== '' && str_contains($text, $excludedNeedle)) {
                    $matchedKeywords = [];
                    break;
                }
            }

            if ($matchedKeywords === []) {
                continue;
            }

            $matchedGroups[] = [
                'key' => $groupKey,
                'title' => $group['title'] ?? $groupKey,
                'matched_keywords' => $matchedKeywords,
                'requirements' => $group['requirements'] ?? [],
            ];
            foreach (($group['requirements'] ?? []) as $requirement) {
                if (! in_array($requirement, $requirements, true)) {
                    $requirements[] = $requirement;
                }
            }
        }

        return [
            'common_preflight' => $rules['common_preflight'] ?? [],
            'groups' => $matchedGroups,
            'requirements' => $requirements,
            'needs_clarification' => $matchedGroups === [],
            'default_only' => $matchedGroups === [],
            'official_worksheet_overrides_classifier' => (bool) ($rules['official_worksheet_overrides_classifier'] ?? true),
        ];
    }

    private function normalize(string $value): string
    {
        $value = strtr(mb_strtolower($value, 'UTF-8'), [
            'ي' => 'ی',
            'ى' => 'ی',
            'ك' => 'ک',
            'ۀ' => 'ه',
            'ة' => 'ه',
            'أ' => 'ا',
            'إ' => 'ا',
            'ؤ' => 'و',
            'ئ' => 'ی',
            '‌' => ' ',
        ]);

        $value = preg_replace('/[^\p{L}\p{N}\s]/u', ' ', $value) ?? $value;
        return trim(preg_replace('/\s+/u', ' ', $value) ?? $value);
    }
}

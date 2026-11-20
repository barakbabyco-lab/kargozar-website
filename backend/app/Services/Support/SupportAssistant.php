<?php

namespace App\Services\Support;

class SupportAssistant
{
    /**
     * Return a reviewed answer only when the message clearly matches a known FAQ.
     * This first version is deliberately deterministic: it never invents prices,
     * timelines, legal requirements or licensing outcomes.
     */
    public function reply(string $message): string
    {
        $text = $this->normalize($message);

        foreach (config('support_assistant.missing_requirement_phrases', []) as $phrase) {
            if ($phrase !== '' && str_contains($text, $this->normalize($phrase))) {
                return config('support_assistant.missing_requirement_response');
            }
        }

        foreach (config('support_assistant.escalation_terms', []) as $term) {
            if ($term !== '' && str_contains($text, $this->normalize($term))) {
                return config('support_assistant.fallback');
            }
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
            $answer = $best['answer'];
            if (($best['service_assurance'] ?? false) === true) {
                $closing = (string) config('support_assistant.service_assurance_closing', '');
                if ($closing !== '' && ! str_contains($answer, $closing)) {
                    $answer = rtrim($answer) . "\n\n" . $closing;
                }
            }

            return $answer;
        }

        return config('support_assistant.fallback');
    }

    /**
     * Classify a guild activity into one or more specialist requirement groups.
     * This is a first-pass heuristic; the official worksheet for the exact activity
     * remains authoritative and can add or override requirements.
     *
     * @return array{common_preflight: array, groups: array, requirements: array, needs_clarification: bool, default_only: bool}
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

        $value = preg_replace('/[^\\p{L}\\p{N}\\s]/u', ' ', $value) ?? $value;
        return trim(preg_replace('/\\s+/u', ' ', $value) ?? $value);
    }
}

<?php

namespace App\Services\Support;

use App\Models\SupportUnansweredQuestionEvent;

class UnansweredQuestionTracker
{
    public function record(string $question, string $outcome, ?int $conversationId = null): void
    {
        $sample = $this->redact($question);
        $sample = trim(mb_substr($sample, 0, 1000, 'UTF-8'));
        if ($sample === '') {
            return;
        }

        $normalized = mb_strtolower($sample, 'UTF-8');
        $normalized = strtr($normalized, ['ي' => 'ی', 'ك' => 'ک', '‌' => ' ']);
        $normalized = trim(preg_replace('/\s+/u', ' ', $normalized) ?? $normalized);

        SupportUnansweredQuestionEvent::create([
            'question_hash' => hash('sha256', $normalized),
            'question_sample' => $sample,
            'outcome' => in_array($outcome, ['web_answered', 'web_no_result', 'human_escalation', 'no_answer'], true) ? $outcome : 'no_answer',
            'conversation_id' => $conversationId,
            'created_at' => now(),
        ]);
    }

    private function redact(string $question): string
    {
        $question = preg_replace('/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/iu', '[ایمیل حذف شد]', $question) ?? $question;
        $question = strtr($question, [
            '۰' => '0', '۱' => '1', '۲' => '2', '۳' => '3', '۴' => '4',
            '۵' => '5', '۶' => '6', '۷' => '7', '۸' => '8', '۹' => '9',
            '٠' => '0', '١' => '1', '٢' => '2', '٣' => '3', '٤' => '4',
            '٥' => '5', '٦' => '6', '٧' => '7', '٨' => '8', '٩' => '9',
        ]);
        $question = preg_replace('/(?<!\d)(?:(?:\+|00)?98|0)?9\d{9}(?!\d)/u', '[شماره حذف شد]', $question) ?? $question;
        $question = preg_replace('/(?<!\d)\d{10}(?!\d)/u', '[شناسه عددی حذف شد]', $question) ?? $question;

        return trim($question);
    }
}

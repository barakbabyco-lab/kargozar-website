<?php

namespace App\Services\Support;

use App\Models\SupportUnansweredQuestionEvent;
use Illuminate\Support\Facades\DB;

class UnansweredQuestionReport
{
    public function build(int $days = 7): array
    {
        $end = now();
        $start = $end->copy()->subDays($days);
        $previousStart = $start->copy()->subDays($days);

        $current = $this->aggregate($start, $end);
        $previous = $this->aggregate($previousStart, $start);

        return [
            'period' => [
                'from' => $start->toIso8601String(),
                'to' => $end->toIso8601String(),
                'timezone' => config('app.timezone', 'Asia/Tehran'),
                'days' => $days,
            ],
            'totals' => [
                'events' => (int) ($current['events'] ?? 0),
                'unique_questions' => count($current['groups']),
                'web_answered' => (int) ($current['web_answered'] ?? 0),
                'web_no_result' => (int) ($current['web_no_result'] ?? 0),
                'human_escalation' => (int) ($current['human_escalation'] ?? 0),
                'no_answer' => (int) ($current['no_answer'] ?? 0),
                'previous_period_events' => (int) ($previous['events'] ?? 0),
            ],
            'groups' => $current['groups'],
            'comparison' => $this->compare($current['groups'], $previous['groups']),
            'generated_at' => now()->toIso8601String(),
        ];
    }

    private function aggregate($start, $end): array
    {
        $rows = SupportUnansweredQuestionEvent::query()
            ->where('created_at', '>=', $start)
            ->where('created_at', '<', $end)
            ->select([
                'question_hash',
                DB::raw('MAX(question_sample) as question_sample'),
                DB::raw('COUNT(*) as occurrences'),
                DB::raw("SUM(CASE WHEN outcome = 'web_answered' THEN 1 ELSE 0 END) as web_answered"),
                DB::raw("SUM(CASE WHEN outcome = 'web_no_result' THEN 1 ELSE 0 END) as web_no_result"),
                DB::raw("SUM(CASE WHEN outcome = 'human_escalation' THEN 1 ELSE 0 END) as human_escalation"),
                DB::raw("SUM(CASE WHEN outcome = 'no_answer' THEN 1 ELSE 0 END) as no_answer"),
                DB::raw('MAX(created_at) as last_seen'),
            ])
            ->groupBy('question_hash')
            ->orderByDesc('occurrences')
            ->limit(300)
            ->get();

        $groups = $rows->map(function ($row) {
            $sample = (string) $row->question_sample;
            return [
                'question' => $sample,
                'question_hash' => $row->question_hash,
                'occurrences' => (int) $row->occurrences,
                'last_seen' => $row->last_seen,
                'outcomes' => [
                    'web_answered' => (int) $row->web_answered,
                    'web_no_result' => (int) $row->web_no_result,
                    'human_escalation' => (int) $row->human_escalation,
                    'no_answer' => (int) $row->no_answer,
                ],
                'suggested_scope' => $this->classifyScope($sample),
            ];
        })->all();

        return [
            'events' => array_sum(array_column($groups, 'occurrences')),
            'web_answered' => array_sum(array_column(array_column($groups, 'outcomes'), 'web_answered')),
            'web_no_result' => array_sum(array_column(array_column($groups, 'outcomes'), 'web_no_result')),
            'human_escalation' => array_sum(array_column(array_column($groups, 'outcomes'), 'human_escalation')),
            'no_answer' => array_sum(array_column(array_column($groups, 'outcomes'), 'no_answer')),
            'groups' => $groups,
        ];
    }

    private function compare(array $current, array $previous): array
    {
        $previousByHash = [];
        foreach ($previous as $group) {
            $previousByHash[$group['question_hash']] = $group;
        }

        $comparison = [];
        foreach ($current as $group) {
            $oldCount = (int) ($previousByHash[$group['question_hash']]['occurrences'] ?? 0);
            $comparison[] = [
                'question' => $group['question'],
                'current_occurrences' => $group['occurrences'],
                'previous_occurrences' => $oldCount,
                'change' => $group['occurrences'] - $oldCount,
                'status' => $oldCount === 0 ? 'new' : ($group['occurrences'] > $oldCount ? 'increased' : ($group['occurrences'] < $oldCount ? 'decreased' : 'unchanged')),
            ];
        }

        return $comparison;
    }

    private function classifyScope(string $question): string
    {
        $text = mb_strtolower($question, 'UTF-8');
        foreach (['جواز', 'مجوز', 'پروانه', 'ثبت شرکت', 'ثبت برند', 'مالیات', 'اینماد', 'استاندارد', 'کارت بهداشت', 'قرارداد', 'اجاره', 'حساب جاری'] as $term) {
            if (str_contains($text, $term)) {
                return 'kargozar_service_candidate';
            }
        }

        foreach (['هوا', 'آب و هوا', 'پایتخت', 'تاریخ', 'ساعت', 'ترجمه', 'معنی', 'ریاضی', 'ورزش', 'فیلم', 'غذا'] as $term) {
            if (str_contains($text, $term)) {
                return 'general_question_candidate';
            }
        }

        return 'needs_human_review';
    }
}

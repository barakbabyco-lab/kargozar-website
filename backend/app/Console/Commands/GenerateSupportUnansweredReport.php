<?php

namespace App\Console\Commands;

use App\Services\Support\UnansweredQuestionReport;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;

class GenerateSupportUnansweredReport extends Command
{
    protected $signature = 'support:report-unanswered-questions {--days=7}';

    protected $description = 'Generate an anonymized weekly report of customer questions not answered from the internal knowledge bank';

    public function handle(UnansweredQuestionReport $report): int
    {
        $days = max(1, min(31, (int) $this->option('days')));
        $payload = $report->build($days);
        $directory = storage_path('app/reports');
        File::ensureDirectoryExists($directory);
        $path = $directory.'/support-unanswered-questions-latest.json';
        File::put($path, json_encode($payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));

        $this->info('گزارش پرسش‌های بی‌پاسخ ذخیره شد: '.$path);
        $this->line('تعداد رخدادها: '.$payload['totals']['events']);
        $this->line('تعداد پرسش‌های یکتا: '.$payload['totals']['unique_questions']);

        return self::SUCCESS;
    }
}

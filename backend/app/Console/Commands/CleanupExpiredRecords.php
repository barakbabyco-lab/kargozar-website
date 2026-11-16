<?php

namespace App\Console\Commands;

use App\Models\IdempotencyKey;
use App\Models\OtpChallenge;
use Illuminate\Console\Command;

class CleanupExpiredRecords extends Command
{
    protected $signature = 'kargozar:cleanup-expired';

    protected $description = 'Delete expired OTP challenges and idempotency records.';

    public function handle(): int
    {
        $expiredOtps = OtpChallenge::query()
            ->where('created_at', '<', now()->subDay())
            ->delete();

        $expiredKeys = IdempotencyKey::query()
            ->whereNotNull('expires_at')
            ->where('expires_at', '<', now())
            ->delete();

        $this->info("Deleted {$expiredOtps} old OTP challenges and {$expiredKeys} expired idempotency keys.");

        return self::SUCCESS;
    }
}

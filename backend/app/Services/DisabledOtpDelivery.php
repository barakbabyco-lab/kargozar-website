<?php

namespace App\Services;

use RuntimeException;

class DisabledOtpDelivery implements OtpDelivery
{
    public function send(string $mobile, string $code): void
    {
        throw new RuntimeException('OTP delivery provider is not configured.');
    }
}

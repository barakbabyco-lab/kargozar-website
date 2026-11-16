<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use RuntimeException;

class IppanelOtpDelivery implements OtpDelivery
{
    public function send(string $mobile, string $code): void
    {
        $apiKey = (string) config('services.ippanel.api_key');
        $patternCode = (string) config('services.ippanel.pattern_code');
        $fromNumber = (string) config('services.ippanel.from_number');

        if ($apiKey === '' || $patternCode === '' || $fromNumber === '') {
            throw new RuntimeException('IPPanel OTP configuration is incomplete.');
        }

        $recipient = $this->toE164($mobile);

        $response = Http::timeout(20)
            ->withHeaders([
                'Authorization' => $apiKey,
                'Accept' => 'application/json',
            ])
            ->post('https://edge.ippanel.com/v1/api/send', [
                'sending_type' => 'pattern',
                'from_number' => $fromNumber,
                'code' => $patternCode,
                'recipients' => [$recipient],
                'params' => [
                    'code' => $code,
                ],
            ]);

        if (! $response->successful() || $response->json('meta.status') !== true) {
            throw new RuntimeException('IPPanel did not accept the OTP message.');
        }
    }

    private function toE164(string $mobile): string
    {
        $digits = preg_replace('/\D+/', '', $mobile) ?? '';

        if (preg_match('/^09[0-9]{9}$/', $digits) === 1) {
            return '+98'.substr($digits, 1);
        }

        if (preg_match('/^989[0-9]{9}$/', $digits) === 1) {
            return '+'.$digits;
        }

        throw new RuntimeException('Invalid Iranian mobile number for IPPanel.');
    }
}

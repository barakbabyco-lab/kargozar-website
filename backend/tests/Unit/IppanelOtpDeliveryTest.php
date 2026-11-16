<?php

namespace Tests\\Unit;

use App\\Services\\IppanelOtpDelivery;
use Illuminate\\Support\\Facades\\Http;
use RuntimeException;
use Tests\\TestCase;

class IppanelOtpDeliveryTest extends TestCase
{
    public function test_it_sends_a_pattern_message_using_edge_api_and_e164_recipient(): void
    {
        config([
            'services.ippanel.api_key' => 'test-api-key',
            'services.ippanel.pattern_code' => 'approved-pattern-code',
            'services.ippanel.from_number' => '+983000505',
        ]);

        Http::fake([
            'https://edge.ippanel.com/v1/api/send' => Http::response([
                'data' => ['message_outbox_ids' => [123]],
                'meta' => ['status' => true, 'message' => 'accepted'],
            ], 200),
        ]);

        app(IppanelOtpDelivery::class)->send('09123456789', '123456');

        Http::assertSent(function ($request): bool {
            return $request->url() === 'https://edge.ippanel.com/v1/api/send'
                && $request->method() === 'POST'
                && $request->hasHeader('Authorization', 'test-api-key')
                && $request['sending_type'] === 'pattern'
                && $request['from_number'] === '+983000505'
                && $request['code'] === 'approved-pattern-code'
                && $request['recipients'] === ['+989123456789']
                && $request['params'] === ['code' => '123456'];
        });
    }

    public function test_it_rejects_an_unaccepted_pattern_request(): void
    {
        config([
            'services.ippanel.api_key' => 'test-api-key',
            'services.ippanel.pattern_code' => 'approved-pattern-code',
            'services.ippanel.from_number' => '+983000505',
        ]);

        Http::fake([
            'https://edge.ippanel.com/v1/api/send' => Http::response([
                'meta' => ['status' => false, 'message' => 'rejected'],
            ], 422),
        ]);

        $this->expectException(RuntimeException::class);

        app(IppanelOtpDelivery::class)->send('09123456789', '123456');
    }

    public function test_it_rejects_invalid_mobile_numbers_before_sending(): void
    {
        config([
            'services.ippanel.api_key' => 'test-api-key',
            'services.ippanel.pattern_code' => 'approved-pattern-code',
            'services.ippanel.from_number' => '+983000505',
        ]);

        Http::fake();

        $this->expectException(RuntimeException::class);

        app(IppanelOtpDelivery::class)->send('12345', '123456');
    }
}

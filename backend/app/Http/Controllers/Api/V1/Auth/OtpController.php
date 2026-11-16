<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\OtpChallenge;
use App\Services\OtpDelivery;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Validator;
use Throwable;

class OtpController extends Controller
{
    public function request(Request $request, OtpDelivery $delivery): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'mobile' => ['required', 'regex:/^09[0-9]{9}$/'],
        ]);

        if ($validator->fails()) {
            return $this->validationError($validator->errors()->toArray());
        }

        $mobile = $validator->validated()['mobile'];
        $mobileKey = 'otp-mobile:'.hash('sha256', $mobile);
        $ipKey = 'otp-ip:'.hash('sha256', (string) $request->ip());

        if (RateLimiter::tooManyAttempts($mobileKey, 3) || RateLimiter::tooManyAttempts($ipKey, 10)) {
            return response()->json([
                'error' => [
                    'code' => 'RATE_LIMITED',
                    'message' => 'تعداد درخواست‌ها بیش از حد مجاز است. کمی بعد دوباره تلاش کنید.',
                ],
            ], 429);
        }

        RateLimiter::hit($mobileKey, 60);
        RateLimiter::hit($ipKey, 60);

        $code = (string) random_int(100000, 999999);

        OtpChallenge::query()
            ->where('mobile', $mobile)
            ->whereNull('consumed_at')
            ->update(['consumed_at' => now()]);

        $challenge = OtpChallenge::create([
            'mobile' => $mobile,
            'code_hash' => Hash::make($code),
            'expires_at' => now()->addMinutes(5),
            'request_ip_hash' => hash('sha256', (string) $request->ip()),
        ]);

        try {
            $delivery->send($mobile, $code);
        } catch (Throwable) {
            $challenge->delete();

            return response()->json([
                'error' => [
                    'code' => 'OTP_DELIVERY_UNAVAILABLE',
                    'message' => 'در حال حاضر ارسال کد امکان‌پذیر نیست. لطفاً بعداً تلاش کنید.',
                ],
            ], 503);
        }

        return response()->json([
            'message' => 'در صورت معتبر بودن شماره، کد ورود ارسال می‌شود.',
        ], 202);
    }

    public function verify(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'mobile' => ['required', 'regex:/^09[0-9]{9}$/'],
            'code' => ['required', 'string', 'regex:/^[0-9]{4,8}$/'],
        ]);

        if ($validator->fails()) {
            return $this->validationError($validator->errors()->toArray());
        }

        $validated = $validator->validated();

        $result = DB::transaction(function () use ($validated) {
            $challenge = OtpChallenge::query()
                ->where('mobile', $validated['mobile'])
                ->whereNull('consumed_at')
                ->latest('id')
                ->lockForUpdate()
                ->first();

            if (
                ! $challenge ||
                $challenge->expires_at->isPast() ||
                $challenge->attempts >= 5
            ) {
                return ['error' => 'invalid'];
            }

            if (! Hash::check($validated['code'], $challenge->code_hash)) {
                $challenge->increment('attempts');

                return ['error' => 'invalid'];
            }

            $challenge->update(['consumed_at' => now()]);

            $customer = Customer::firstOrCreate(
                ['mobile' => $validated['mobile']],
                ['status' => 'active'],
            );

            if ($customer->status !== 'active') {
                return ['error' => 'blocked'];
            }

            $customer->forceFill(['mobile_verified_at' => now()])->save();

            $token = $customer->createToken(
                'customer-app',
                ['*'],
                now()->addDays(30),
            );

            return [
                'customer' => $customer,
                'token' => $token,
            ];
        });

        if (($result['error'] ?? null) === 'blocked') {
            return response()->json([
                'error' => [
                    'code' => 'ACCOUNT_BLOCKED',
                    'message' => 'امکان ورود به حساب کاربری وجود ندارد.',
                ],
            ], 403);
        }

        if (isset($result['error'])) {
            return response()->json([
                'error' => [
                    'code' => 'INVALID_OTP',
                    'message' => 'کد واردشده معتبر نیست یا مهلت آن پایان یافته است.',
                ],
            ], 422);
        }

        return response()->json([
            'data' => [
                'access_token' => $result['token']->plainTextToken,
                'token_type' => 'Bearer',
                'expires_at' => $result['token']->accessToken->expires_at?->toISOString(),
                'customer' => [
                    'id' => (string) $result['customer']->id,
                    'mobile' => $result['customer']->mobile,
                    'full_name' => $result['customer']->full_name,
                ],
            ],
        ]);
    }

    private function validationError(array $fields): JsonResponse
    {
        return response()->json([
            'error' => [
                'code' => 'VALIDATION_ERROR',
                'message' => 'اطلاعات ارسالی معتبر نیست.',
                'fields' => $fields,
            ],
        ], 422);
    }
}

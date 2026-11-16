<?php

namespace App\Http\Controllers\Api\V1\Staff\Auth;

use App\Http\Controllers\Controller;
use App\Models\StaffUser;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Validator;

class StaffLoginController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'email' => ['required', 'email', 'max:190'],
            'password' => ['required', 'string', 'max:200'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'اطلاعات ورود معتبر نیست.',
                    'fields' => $validator->errors()->toArray(),
                ],
            ], 422);
        }

        $data = $validator->validated();
        $limitKey = 'staff-login:'.hash('sha256', strtolower($data['email']).'|'.$request->ip());

        if (RateLimiter::tooManyAttempts($limitKey, 5)) {
            return response()->json([
                'error' => [
                    'code' => 'RATE_LIMITED',
                    'message' => 'تعداد تلاش‌های ورود بیش از حد مجاز است.',
                ],
            ], 429);
        }

        $staff = StaffUser::query()
            ->where('email', strtolower($data['email']))
            ->first();

        if (! $staff || ! $staff->is_active || ! Hash::check($data['password'], $staff->password)) {
            RateLimiter::hit($limitKey, 60);

            return response()->json([
                'error' => [
                    'code' => 'INVALID_CREDENTIALS',
                    'message' => 'ایمیل یا گذرواژه صحیح نیست.',
                ],
            ], 401);
        }

        RateLimiter::clear($limitKey);
        $staff->forceFill(['last_login_at' => now()])->save();

        $token = $staff->createToken(
            'staff-portal',
            ['staff:'.$staff->role],
            now()->addHours(12),
        );

        return response()->json([
            'data' => [
                'access_token' => $token->plainTextToken,
                'token_type' => 'Bearer',
                'expires_at' => $token->accessToken->expires_at?->toISOString(),
                'staff' => [
                    'id' => (string) $staff->id,
                    'name' => $staff->name,
                    'email' => $staff->email,
                    'role' => $staff->role,
                ],
            ],
        ]);
    }
}

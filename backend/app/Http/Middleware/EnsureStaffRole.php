<?php

namespace App\Http\Middleware;

use App\Models\StaffUser;
use Closure;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureStaffRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $staff = $request->user();

        if (! $staff instanceof StaffUser || ! $staff->is_active) {
            return new JsonResponse([
                'error' => [
                    'code' => 'STAFF_ACCESS_REQUIRED',
                    'message' => 'دسترسی کارکنان برای این عملیات لازم است.',
                ],
            ], 403);
        }

        if ($roles !== [] && ! in_array($staff->role, $roles, true)) {
            return new JsonResponse([
                'error' => [
                    'code' => 'INSUFFICIENT_ROLE',
                    'message' => 'نقش کاربری شما اجازه انجام این عملیات را نمی‌دهد.',
                ],
            ], 403);
        }

        return $next($request);
    }
}

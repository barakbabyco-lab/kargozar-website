<?php

use App\\Console\\Commands\\CreateStaffUser;
use App\\Http\\Middleware\\EnsureStaffRole;
use Illuminate\\Auth\\AuthenticationException;
use Illuminate\\Database\\Eloquent\\ModelNotFoundException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withCommands([CreateStaffUser::class])
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'staff.role' => EnsureStaffRole::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson(),
        );

        $exceptions->render(function (AuthenticationException $exception, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'error' => [
                        'code' => 'UNAUTHENTICATED',
                        'message' => 'برای ادامه ابتدا وارد حساب کاربری شوید.',
                    ],
                ], 401);
            }
        });

        $exceptions->render(function (ModelNotFoundException $exception, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'error' => [
                        'code' => 'NOT_FOUND',
                        'message' => 'مورد درخواستی پیدا نشد.',
                    ],
                ], 404);
            }
        });
    })->create();

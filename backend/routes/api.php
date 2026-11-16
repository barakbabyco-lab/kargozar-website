<?php

use App\Http\Controllers\Api\V1\Auth\LogoutController;
use App\Http\Controllers\Api\V1\Auth\OtpController;
use App\Http\Controllers\Api\V1\ServiceCategoryController;
use App\Http\Controllers\Api\V1\ServiceController;
use App\Http\Controllers\Api\V1\ServiceRequestController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::prefix('auth')->group(function (): void {
        Route::post('otp/request', [OtpController::class, 'request'])->middleware('throttle:10,1');
        Route::post('otp/verify', [OtpController::class, 'verify'])->middleware('throttle:10,1');
    });

    Route::get('service-categories', [ServiceCategoryController::class, 'index']);
    Route::get('services', [ServiceController::class, 'index']);
    Route::get('services/{slug}', [ServiceController::class, 'show']);

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::post('auth/logout', LogoutController::class);
        Route::post('service-requests', [ServiceRequestController::class, 'store']);
        Route::get('me/service-requests', [ServiceRequestController::class, 'index']);
        Route::get('me/service-requests/{trackingCode}', [ServiceRequestController::class, 'show']);
    });
});

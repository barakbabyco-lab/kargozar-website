<?php

use App\Http\Controllers\Api\V1\Auth\LogoutController;
use App\Http\Controllers\Api\V1\Auth\OtpController;
use App\Http\Controllers\Api\V1\ServiceCategoryController;
use App\Http\Controllers\Api\V1\ServiceController;
use App\Http\Controllers\Api\V1\ServiceRequestController;
use App\Http\Controllers\Api\V1\Staff\Auth\StaffLoginController;
use App\Http\Controllers\Api\V1\Staff\StaffCatalogController;
use App\Http\Controllers\Api\V1\Staff\StaffServiceRequestController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::prefix('auth')->group(function (): void {
        Route::post('otp/request', [OtpController::class, 'request'])->middleware('throttle:10,1');
        Route::post('otp/verify', [OtpController::class, 'verify'])->middleware('throttle:10,1');
    });

    Route::get('service-categories', [ServiceCategoryController::class, 'index']);
    Route::get('services', [ServiceController::class, 'index']);
    Route::get('services/{slug}', [ServiceController::class, 'show']);

    Route::post('staff/auth/login', StaffLoginController::class)->middleware('throttle:10,1');

    Route::middleware(['auth:sanctum', 'staff.role:admin,supervisor,expert,finance,support'])
        ->prefix('staff')
        ->group(function (): void {
            Route::post('auth/logout', LogoutController::class);
            Route::get('catalog/categories', [StaffCatalogController::class, 'categories']);
            Route::get('catalog/services', [StaffCatalogController::class, 'services']);
            Route::post('catalog/categories', [StaffCatalogController::class, 'storeCategory'])
                ->middleware('staff.manager:admin,supervisor');
            Route::patch('catalog/categories/{categoryId}', [StaffCatalogController::class, 'updateCategory'])
                ->middleware('staff.manager:admin,supervisor');
            Route::post('catalog/services', [StaffCatalogController::class, 'storeService'])
                ->middleware('staff.manager:admin,supervisor');
            Route::patch('catalog/services/{serviceId}', [StaffCatalogController::class, 'updateService'])
                ->middleware('staff.manager:admin,supervisor');
            Route::get('service-requests', [StaffServiceRequestController::class, 'index']);
            Route::get('service-requests/{trackingCode}', [StaffServiceRequestController::class, 'show']);
            Route::post('service-requests/{trackingCode}/events', [StaffServiceRequestController::class, 'recordEvent'])
                ->middleware('staff.editor:admin,supervisor,expert');
            Route::patch('service-requests/{trackingCode}/assignment', [StaffServiceRequestController::class, 'assign'])
                ->middleware('staff.manager:admin,supervisor');
        });

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::post('auth/logout', LogoutController::class);
        Route::post('service-requests', [ServiceRequestController::class, 'store']);
        Route::get('me/service-requests', [ServiceRequestController::class, 'index']);
        Route::get('me/service-requests/{trackingCode}', [ServiceRequestController::class, 'show']);
    });
});

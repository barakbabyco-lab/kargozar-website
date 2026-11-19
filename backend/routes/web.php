<?php

use App\Http\Controllers\StaffPortalController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/staff/portal/login', [StaffPortalController::class, 'loginForm'])->name('staff.portal.login');
Route::post('/staff/portal/login', [StaffPortalController::class, 'authenticate'])->middleware('throttle:10,1')->name('staff.portal.authenticate');

Route::middleware(['auth:staff', 'staff.role:admin,supervisor,expert,support'])
    ->prefix('staff/portal')
    ->name('staff.portal.')
    ->group(function (): void {
        Route::get('/', [StaffPortalController::class, 'index'])->name('index');
        Route::get('/conversations/{conversationId}', [StaffPortalController::class, 'show'])->name('show');
        Route::post('/conversations/{conversationId}/reply', [StaffPortalController::class, 'reply'])->name('reply');
        Route::patch('/conversations/{conversationId}/status', [StaffPortalController::class, 'updateStatus'])->name('status');
        Route::post('/logout', [StaffPortalController::class, 'logout'])->name('logout');
    });

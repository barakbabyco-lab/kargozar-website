<?php

namespace App\Providers;

use App\Services\DisabledOtpDelivery;
use App\Services\IppanelOtpDelivery;
use App\Services\OtpDelivery;
use App\Services\Support\GuidedSupportAssistant;
use App\Services\Support\SupportAssistant;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(SupportAssistant::class, GuidedSupportAssistant::class);

        $this->app->bind(OtpDelivery::class, function ($app): OtpDelivery {
            $configured = config('services.ippanel.api_key')
                && config('services.ippanel.pattern_code')
                && config('services.ippanel.from_number');

            return $configured
                ? $app->make(IppanelOtpDelivery::class)
                : $app->make(DisabledOtpDelivery::class);
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Schema::defaultStringLength(191);
    }
}

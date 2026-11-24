<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('services', function (Blueprint $table): void {
            if (! Schema::hasColumn('services', 'price_verified_at')) {
                $table->timestamp('price_verified_at')->nullable();
            }

            if (! Schema::hasColumn('services', 'duration_verified_at')) {
                $table->timestamp('duration_verified_at')->nullable();
            }
        });
    }

    public function down(): void
    {
        Schema::table('services', function (Blueprint $table): void {
            if (Schema::hasColumn('services', 'price_verified_at')) {
                $table->dropColumn('price_verified_at');
            }

            if (Schema::hasColumn('services', 'duration_verified_at')) {
                $table->dropColumn('duration_verified_at');
            }
        });
    }
};

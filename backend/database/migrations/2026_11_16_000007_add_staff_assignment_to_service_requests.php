<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('service_requests', function (Blueprint $table) {
            $table->foreignId('assigned_staff_id')
                ->nullable()
                ->after('service_id')
                ->constrained('staff_users')
                ->restrictOnDelete();
            $table->index(['assigned_staff_id', 'status', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::table('service_requests', function (Blueprint $table) {
            $table->dropIndex(['assigned_staff_id', 'status', 'created_at']);
            $table->dropConstrainedForeignId('assigned_staff_id');
        });
    }
};

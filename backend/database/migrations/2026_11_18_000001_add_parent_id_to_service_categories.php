<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('service_categories', function (Blueprint $table) {
            $table->foreignId('parent_id')
                ->nullable()
                ->after('id')
                ->constrained('service_categories')
                ->restrictOnDelete();

            $table->index(['parent_id', 'is_active', 'sort_order'], 'service_categories_parent_active_order_index');
        });
    }

    public function down(): void
    {
        Schema::table('service_categories', function (Blueprint $table) {
            $table->dropIndex('service_categories_parent_active_order_index');
            $table->dropConstrainedForeignId('parent_id');
        });
    }
};

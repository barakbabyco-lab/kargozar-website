<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('service_requests', function (Blueprint $table) {
            $table->id();
            $table->uuid('public_id')->unique();
            $table->foreignId('customer_id')->constrained('customers')->restrictOnDelete();
            $table->foreignId('service_id')->constrained('services')->restrictOnDelete();
            $table->string('tracking_code', 32)->unique();
            $table->string('status', 32)->default('submitted')->index();
            $table->text('customer_note')->nullable();
            $table->decimal('quoted_price', 13, 2)->nullable();
            $table->char('currency', 3)->default('IRR');
            $table->timestamps();
            $table->index(['customer_id', 'created_at']);
            $table->index(['status', 'created_at']);
            $table->index(['service_id', 'created_at']);
        });

        Schema::create('request_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('service_request_id')->constrained('service_requests')->cascadeOnDelete();
            $table->string('actor_type', 24);
            $table->unsignedBigInteger('actor_id')->nullable();
            $table->string('status', 32)->nullable();
            $table->text('public_message')->nullable();
            $table->text('internal_note')->nullable();
            $table->timestamps();
            $table->index(['service_request_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('request_events');
        Schema::dropIfExists('service_requests');
    }
};

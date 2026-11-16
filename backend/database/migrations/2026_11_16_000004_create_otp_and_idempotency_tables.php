<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('otp_challenges', function (Blueprint $table) {
            $table->id();
            $table->string('mobile', 11)->index();
            $table->string('code_hash', 255);
            $table->timestamp('expires_at')->index();
            $table->unsignedTinyInteger('attempts')->default(0);
            $table->timestamp('consumed_at')->nullable();
            $table->char('request_ip_hash', 64)->nullable();
            $table->timestamps();
            $table->index(['mobile', 'expires_at']);
        });

        Schema::create('idempotency_keys', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained('customers')->cascadeOnDelete();
            $table->char('key_hash', 64);
            $table->char('request_hash', 64);
            $table->json('response_json')->nullable();
            $table->unsignedSmallInteger('response_status')->nullable();
            $table->timestamp('expires_at')->nullable()->index();
            $table->timestamps();
            $table->unique(['customer_id', 'key_hash']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('idempotency_keys');
        Schema::dropIfExists('otp_challenges');
    }
};

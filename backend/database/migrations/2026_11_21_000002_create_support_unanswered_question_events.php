<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('support_unanswered_question_events', function (Blueprint $table) {
            $table->id();
            $table->char('question_hash', 64)->index();
            $table->text('question_sample');
            $table->string('outcome', 24)->index();
            $table->foreignId('conversation_id')->nullable()->constrained('support_conversations')->nullOnDelete();
            $table->timestamp('created_at')->useCurrent()->index();
            $table->index(['question_hash', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('support_unanswered_question_events');
    }
};

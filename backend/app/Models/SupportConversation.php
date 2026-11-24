<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class SupportConversation extends Model
{
    protected $fillable = ['customer_id', 'guest_token_hash', 'contact_mobile', 'assigned_staff_id', 'status', 'last_message_at', 'assistant_context'];

    protected function casts(): array
    {
        return [
            'last_message_at' => 'datetime',
            'assistant_context' => 'array',
        ];
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function assignedStaff(): BelongsTo
    {
        return $this->belongsTo(StaffUser::class, 'assigned_staff_id');
    }

    public function messages(): HasMany
    {
        return $this->hasMany(SupportMessage::class, 'conversation_id');
    }
}

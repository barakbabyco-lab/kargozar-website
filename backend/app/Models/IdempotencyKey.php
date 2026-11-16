<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class IdempotencyKey extends Model
{
    protected $fillable = [
        'customer_id',
        'key_hash',
        'request_hash',
        'response_json',
        'response_status',
        'expires_at',
    ];

    protected function casts(): array
    {
        return [
            'response_json' => 'array',
            'response_status' => 'integer',
            'expires_at' => 'datetime',
        ];
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }
}

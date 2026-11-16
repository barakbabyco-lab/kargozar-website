<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ServiceRequest extends Model
{
    protected $fillable = [
        'public_id',
        'customer_id',
        'service_id',
        'tracking_code',
        'status',
        'customer_note',
        'quoted_price',
        'currency',
    ];

    protected function casts(): array
    {
        return ['quoted_price' => 'decimal:2'];
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function service(): BelongsTo
    {
        return $this->belongsTo(Service::class);
    }

    public function events(): HasMany
    {
        return $this->hasMany(RequestEvent::class)->latest();
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class Customer extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = ['mobile', 'full_name', 'status'];

    protected $hidden = ['remember_token'];

    protected function casts(): array
    {
        return [
            'mobile_verified_at' => 'datetime',
        ];
    }

    public function serviceRequests()
    {
        return $this->hasMany(ServiceRequest::class);
    }
}

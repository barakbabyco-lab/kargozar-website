<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ServiceResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'title' => $this->title,
            'slug' => $this->slug,
            'description' => $this->description,
            'requirements' => $this->requirements ?? [],
            'estimated_days' => $this->estimated_days,
            'duration_verified_at' => $this->duration_verified_at?->toIso8601String(),
            'base_price' => $this->base_price,
            'price_verified_at' => $this->price_verified_at?->toIso8601String(),
            'is_active' => (bool) $this->is_active,
            'sort_order' => (int) $this->sort_order,
            'category' => $this->whenLoaded('category', fn () => [
                'name' => $this->category->name,
                'slug' => $this->category->slug,
            ]),
        ];
    }
}

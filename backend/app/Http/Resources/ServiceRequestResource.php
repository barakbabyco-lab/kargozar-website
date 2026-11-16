<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ServiceRequestResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->public_id,
            'tracking_code' => $this->tracking_code,
            'status' => $this->status,
            'customer_note' => $this->customer_note,
            'service' => $this->whenLoaded('service', fn () => [
                'title' => $this->service?->title,
            ]),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
            'events' => $this->whenLoaded('events', fn () => $this->events
                ->whereNull('internal_note')
                ->values()
                ->map(fn ($event) => [
                    'status' => $event->status,
                    'public_message' => $event->public_message,
                    'created_at' => $event->created_at?->toISOString(),
                ])),
        ];
    }
}

<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StaffServiceRequestResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->public_id,
            'tracking_code' => $this->tracking_code,
            'status' => $this->status,
            'customer_note' => $this->customer_note,
            'quoted_price' => $this->quoted_price,
            'currency' => $this->currency,
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
            'customer' => $this->whenLoaded('customer', fn () => [
                'id' => (string) $this->customer->id,
                'mobile' => $this->customer->mobile,
                'full_name' => $this->customer->full_name,
            ]),
            'service' => $this->whenLoaded('service', fn () => [
                'id' => (string) $this->service->id,
                'title' => $this->service->title,
                'slug' => $this->service->slug,
            ]),
            'assigned_staff' => $this->whenLoaded('assignedStaff', fn () => $this->assignedStaff ? [
                'id' => (string) $this->assignedStaff->id,
                'name' => $this->assignedStaff->name,
                'role' => $this->assignedStaff->role,
            ] : null),
            'events' => $this->whenLoaded('events', fn () => $this->events->values()->map(fn ($event) => [
                'status' => $event->status,
                'public_message' => $event->public_message,
                'internal_note' => $event->internal_note,
                'actor_type' => $event->actor_type,
                'actor_id' => $event->actor_id,
                'created_at' => $event->created_at?->toISOString(),
            ])),
        ];
    }
}

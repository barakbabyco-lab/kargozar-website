<?php

namespace App\Http\Controllers\Api\V1\Staff;

use App\Http\Controllers\Controller;
use App\Http\Resources\StaffServiceRequestResource;
use App\Models\AuditLog;
use App\Models\RequestEvent;
use App\Models\ServiceRequest;
use App\Models\StaffUser;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use Illuminate\Support\Str;

class StaffServiceRequestController extends Controller
{
    public function index(Request $request)
    {
        $query = ServiceRequest::query()
            ->with(['customer', 'service', 'assignedStaff', 'events'])
            ->latest();

        if ($request->filled('status')) {
            $query->where('status', $request->string('status')->toString());
        }

        if ($request->boolean('assigned_to_me')) {
            $query->where('assigned_staff_id', $request->user()->getAuthIdentifier());
        }

        if ($request->filled('q')) {
            $term = '%'.$request->string('q')->toString().'%';
            $query->where(function (Builder $builder) use ($term) {
                $builder->where('tracking_code', 'like', $term)
                    ->orWhereHas('customer', fn (Builder $customer) => $customer->where('mobile', 'like', $term))
                    ->orWhereHas('service', fn (Builder $service) => $service->where('title', 'like', $term));
            });
        }

        return StaffServiceRequestResource::collection($query->paginate(30)->withQueryString());
    }

    public function show(Request $request, string $trackingCode): StaffServiceRequestResource
    {
        $serviceRequest = ServiceRequest::query()
            ->with(['customer', 'service', 'assignedStaff', 'events'])
            ->where('tracking_code', $trackingCode)
            ->firstOrFail();

        AuditLog::create([
            'actor_type' => 'staff',
            'actor_id' => $request->user()->getAuthIdentifier(),
            'action' => 'service_request.viewed',
            'subject_type' => ServiceRequest::class,
            'subject_id' => $serviceRequest->id,
            'request_id' => $request->header('X-Request-Id', (string) Str::uuid()),
            'ip_hash' => hash('sha256', (string) $request->ip()),
            'metadata' => ['tracking_code' => $serviceRequest->tracking_code],
        ]);

        return new StaffServiceRequestResource($serviceRequest);
    }

    public function assign(Request $request, string $trackingCode): JsonResponse|StaffServiceRequestResource
    {
        $validator = Validator::make($request->all(), [
            'assigned_staff_id' => ['required', 'integer', 'exists:staff_users,id'],
        ]);

        if ($validator->fails()) {
            return $this->validationError($validator->errors()->toArray());
        }

        $staff = StaffUser::query()
            ->whereKey($validator->validated()['assigned_staff_id'])
            ->where('is_active', true)
            ->first();

        if (! $staff) {
            return $this->validationError([
                'assigned_staff_id' => ['کارشناس انتخاب‌شده فعال نیست.'],
            ]);
        }

        $serviceRequest = DB::transaction(function () use ($request, $trackingCode, $staff) {
            $record = ServiceRequest::query()
                ->where('tracking_code', $trackingCode)
                ->lockForUpdate()
                ->firstOrFail();

            $record->update(['assigned_staff_id' => $staff->id]);

            AuditLog::create([
                'actor_type' => 'staff',
                'actor_id' => $request->user()->getAuthIdentifier(),
                'action' => 'service_request.assigned',
                'subject_type' => ServiceRequest::class,
                'subject_id' => $record->id,
                'request_id' => $request->header('X-Request-Id', (string) Str::uuid()),
                'ip_hash' => hash('sha256', (string) $request->ip()),
                'metadata' => ['assigned_staff_id' => $staff->id],
            ]);

            return $record->load(['customer', 'service', 'assignedStaff', 'events']);
        });

        return new StaffServiceRequestResource($serviceRequest);
    }

    public function recordEvent(Request $request, string $trackingCode): JsonResponse|StaffServiceRequestResource
    {
        $validator = Validator::make($request->all(), [
            'status' => ['nullable', 'string', Rule::in([
                'submitted',
                'reviewing',
                'awaiting_customer',
                'in_progress',
                'completed',
                'rejected',
                'cancelled',
            ])],
            'public_message' => ['nullable', 'string', 'max:2000'],
            'internal_note' => ['nullable', 'string', 'max:4000'],
        ]);

        if ($validator->fails()) {
            return $this->validationError($validator->errors()->toArray());
        }

        $data = $validator->validated();

        if (
            empty($data['status']) &&
            empty($data['public_message']) &&
            empty($data['internal_note'])
        ) {
            return $this->validationError([
                'event' => ['برای ثبت رویداد، وضعیت یا پیام لازم است.'],
            ]);
        }

        $serviceRequest = DB::transaction(function () use ($request, $trackingCode, $data) {
            $record = ServiceRequest::query()
                ->where('tracking_code', $trackingCode)
                ->lockForUpdate()
                ->firstOrFail();

            if (! empty($data['status']) && $data['status'] !== $record->status) {
                $transitions = [
                    'submitted' => ['reviewing', 'cancelled'],
                    'reviewing' => ['awaiting_customer', 'in_progress', 'rejected', 'cancelled'],
                    'awaiting_customer' => ['reviewing', 'in_progress', 'cancelled'],
                    'in_progress' => ['awaiting_customer', 'completed', 'rejected', 'cancelled'],
                    'completed' => [],
                    'rejected' => [],
                    'cancelled' => [],
                ];

                if (! in_array($data['status'], $transitions[$record->status] ?? [], true)) {
                    return ['invalid_transition' => true, 'current_status' => $record->status];
                }

                $record->update(['status' => $data['status']]);
            }

            RequestEvent::create([
                'service_request_id' => $record->id,
                'actor_type' => 'staff',
                'actor_id' => $request->user()->getAuthIdentifier(),
                'status' => $record->status,
                'public_message' => $data['public_message'] ?? null,
                'internal_note' => $data['internal_note'] ?? null,
            ]);

            AuditLog::create([
                'actor_type' => 'staff',
                'actor_id' => $request->user()->getAuthIdentifier(),
                'action' => 'service_request.event_recorded',
                'subject_type' => ServiceRequest::class,
                'subject_id' => $record->id,
                'request_id' => $request->header('X-Request-Id', (string) Str::uuid()),
                'ip_hash' => hash('sha256', (string) $request->ip()),
                'metadata' => [
                    'status' => $record->status,
                    'has_public_message' => ! empty($data['public_message']),
                    'has_internal_note' => ! empty($data['internal_note']),
                ],
            ]);

            return $record->load(['customer', 'service', 'assignedStaff', 'events']);
        });

        if (($serviceRequest['invalid_transition'] ?? false) === true) {
            return response()->json([
                'error' => [
                    'code' => 'INVALID_STATUS_TRANSITION',
                    'message' => 'تغییر وضعیت انتخاب‌شده از وضعیت فعلی مجاز نیست.',
                    'fields' => [
                        'status' => ['وضعیت فعلی: '.$serviceRequest['current_status']],
                    ],
                ],
            ], 422);
        }

        return new StaffServiceRequestResource($serviceRequest);
    }

    private function validationError(array $fields): JsonResponse
    {
        return response()->json([
            'error' => [
                'code' => 'VALIDATION_ERROR',
                'message' => 'اطلاعات ارسالی معتبر نیست.',
                'fields' => $fields,
            ],
        ], 422);
    }
}

<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ServiceRequestResource;
use App\Models\IdempotencyKey;
use App\Models\RequestEvent;
use App\Models\Service;
use App\Models\ServiceRequest;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Throwable;

class ServiceRequestController extends Controller
{
    public function index(Request $request)
    {
        $requests = ServiceRequest::query()
            ->where('customer_id', $request->user()->getAuthIdentifier())
            ->with(['events' => fn ($events) => $events->whereNull('internal_note')])
            ->latest()
            ->paginate(20);

        return ServiceRequestResource::collection($requests);
    }

    public function store(Request $request): JsonResponse
    {
        $key = (string) $request->header('Idempotency-Key', '');

        if (strlen($key) < 16 || strlen($key) > 128) {
            return response()->json([
                'error' => [
                    'code' => 'INVALID_IDEMPOTENCY_KEY',
                    'message' => 'هدر Idempotency-Key باید بین ۱۶ تا ۱۲۸ کاراکتر باشد.',
                ],
            ], 422);
        }

        $validator = Validator::make($request->all(), [
            'service_id' => ['required', 'integer', 'min:1'],
            'customer_note' => ['nullable', 'string', 'max:2000'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'اطلاعات ارسالی معتبر نیست.',
                    'fields' => $validator->errors()->toArray(),
                ],
            ], 422);
        }

        $data = $validator->validated();
        $customerId = (int) $request->user()->getAuthIdentifier();
        $keyHash = hash('sha256', $key);
        $requestHash = hash('sha256', json_encode([
            'service_id' => (int) $data['service_id'],
            'customer_note' => $data['customer_note'] ?? null,
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));

        try {
            $result = DB::transaction(function () use ($data, $customerId, $keyHash, $requestHash) {
                $existing = IdempotencyKey::query()
                    ->where('customer_id', $customerId)
                    ->where('key_hash', $keyHash)
                    ->lockForUpdate()
                    ->first();

                if ($existing) {
                    if (! hash_equals($existing->request_hash, $requestHash)) {
                        return ['conflict' => true];
                    }

                    if ($existing->response_json !== null) {
                        return [
                            'body' => $existing->response_json,
                            'status' => $existing->response_status ?? 201,
                            'replayed' => true,
                        ];
                    }

                    return ['conflict' => true];
                }

                $service = Service::query()
                    ->whereKey($data['service_id'])
                    ->where('is_active', true)
                    ->first();

                if (! $service) {
                    return ['service_missing' => true];
                }

                $idempotency = IdempotencyKey::create([
                    'customer_id' => $customerId,
                    'key_hash' => $keyHash,
                    'request_hash' => $requestHash,
                    'expires_at' => now()->addDays(7),
                ]);

                $serviceRequest = ServiceRequest::create([
                    'public_id' => (string) Str::uuid(),
                    'customer_id' => $customerId,
                    'service_id' => $service->id,
                    'tracking_code' => 'KG-'.Str::upper(Str::random(16)),
                    'status' => 'submitted',
                    'customer_note' => $data['customer_note'] ?? null,
                    'currency' => 'IRR',
                ]);

                RequestEvent::create([
                    'service_request_id' => $serviceRequest->id,
                    'actor_type' => 'customer',
                    'actor_id' => $customerId,
                    'status' => 'submitted',
                    'public_message' => 'درخواست شما ثبت شد و برای بررسی در صف قرار گرفت.',
                ]);

                $body = [
                    'data' => (new ServiceRequestResource(
                        $serviceRequest->load('events'),
                    ))->resolve(),
                ];

                $idempotency->update([
                    'response_json' => $body,
                    'response_status' => 201,
                ]);

                return ['body' => $body, 'status' => 201, 'replayed' => false];
            });
        } catch (QueryException $exception) {
            $existing = IdempotencyKey::query()
                ->where('customer_id', $customerId)
                ->where('key_hash', $keyHash)
                ->first();

            if ($existing && hash_equals($existing->request_hash, $requestHash) && $existing->response_json !== null) {
                return response()->json($existing->response_json, $existing->response_status ?? 201);
            }

            throw $exception;
        } catch (Throwable $exception) {
            throw $exception;
        }

        if (($result['conflict'] ?? false) === true) {
            return response()->json([
                'error' => [
                    'code' => 'IDEMPOTENCY_CONFLICT',
                    'message' => 'این کلید قبلاً برای درخواست دیگری استفاده شده است.',
                ],
            ], 409);
        }

        if (($result['service_missing'] ?? false) === true) {
            return response()->json([
                'error' => [
                    'code' => 'SERVICE_UNAVAILABLE',
                    'message' => 'خدمت انتخاب‌شده در حال حاضر فعال نیست.',
                ],
            ], 404);
        }

        return response()->json($result['body'], $result['status']);
    }

    public function show(Request $request, string $trackingCode): ServiceRequestResource
    {
        $serviceRequest = ServiceRequest::query()
            ->where('customer_id', $request->user()->getAuthIdentifier())
            ->where('tracking_code', $trackingCode)
            ->with(['events' => fn ($events) => $events->whereNull('internal_note')])
            ->firstOrFail();

        return new ServiceRequestResource($serviceRequest);
    }
}

<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\SupportConversation;
use App\Models\SupportMessage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class SupportChatController extends Controller
{
    public function customerIndex(Request $request): JsonResponse
    {
        $items = SupportConversation::query()
            ->where('customer_id', $request->user()->getAuthIdentifier())
            ->with(['messages' => fn ($query) => $query->latest()->limit(1)])
            ->latest('last_message_at')
            ->paginate(20);

        return response()->json(['data' => $items]);
    }

    public function customerStart(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'body' => ['required', 'string', 'min:1', 'max:2000'],
        ]);

        if ($validator->fails()) {
            return $this->validationError($validator->errors()->toArray());
        }

        $conversation = DB::transaction(function () use ($request, $validator) {
            $customerId = $request->user()->getAuthIdentifier();
            $conversation = SupportConversation::query()
                ->where('customer_id', $customerId)
                ->where('status', 'open')
                ->latest('last_message_at')
                ->lockForUpdate()
                ->first();

            if (! $conversation) {
                $conversation = SupportConversation::create([
                    'customer_id' => $customerId,
                    'status' => 'open',
                ]);
            }

            $message = $conversation->messages()->create([
                'sender_type' => 'customer',
                'sender_id' => $customerId,
                'body' => trim($validator->validated()['body']),
            ]);
            $conversation->update(['last_message_at' => $message->created_at]);

            return $conversation->load(['customer', 'messages']);
        });

        return response()->json(['data' => $this->conversationPayload($conversation)], 201);
    }

    public function customerMessages(Request $request, int $conversationId): JsonResponse
    {
        $conversation = SupportConversation::query()
            ->where('customer_id', $request->user()->getAuthIdentifier())
            ->findOrFail($conversationId);

        $messages = $conversation->messages()->orderBy('id')->get();
        $conversation->messages()
            ->where('sender_type', 'staff')
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json(['data' => $messages->map(fn ($message) => $this->messagePayload($message))]);
    }

    public function customerSend(Request $request, int $conversationId): JsonResponse
    {
        $conversation = SupportConversation::query()
            ->where('customer_id', $request->user()->getAuthIdentifier())
            ->findOrFail($conversationId);

        if ($conversation->status !== 'open') {
            return response()->json(['error' => ['code' => 'CONVERSATION_CLOSED', 'message' => 'این گفت‌وگو بسته شده است.']], 409);
        }

        $validator = Validator::make($request->all(), ['body' => ['required', 'string', 'min:1', 'max:2000']]);
        if ($validator->fails()) {
            return $this->validationError($validator->errors()->toArray());
        }

        $message = DB::transaction(function () use ($request, $conversation, $validator) {
            $message = $conversation->messages()->create([
                'sender_type' => 'customer',
                'sender_id' => $request->user()->getAuthIdentifier(),
                'body' => trim($validator->validated()['body']),
            ]);
            $conversation->update(['last_message_at' => $message->created_at]);
            return $message;
        });

        return response()->json(['data' => $this->messagePayload($message)], 201);
    }

    public function staffIndex(Request $request): JsonResponse
    {
        $query = SupportConversation::query()->with('customer')->withCount('messages')->latest('last_message_at');
        if ($request->filled('status')) {
            $query->where('status', $request->string('status')->toString());
        }
        if ($request->boolean('assigned_to_me')) {
            $query->where('assigned_staff_id', $request->user()->getAuthIdentifier());
        }

        return response()->json(['data' => $query->paginate(30)->withQueryString()]);
    }

    public function staffMessages(Request $request, int $conversationId): JsonResponse
    {
        $conversation = SupportConversation::findOrFail($conversationId);
        $messages = $conversation->messages()->orderBy('id')->get();
        $conversation->messages()
            ->where('sender_type', 'customer')
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json(['data' => $messages->map(fn ($message) => $this->messagePayload($message))]);
    }

    public function staffSend(Request $request, int $conversationId): JsonResponse
    {
        $conversation = SupportConversation::findOrFail($conversationId);
        if ($conversation->status !== 'open') {
            return response()->json(['error' => ['code' => 'CONVERSATION_CLOSED', 'message' => 'این گفت‌وگو بسته شده است.']], 409);
        }

        $validator = Validator::make($request->all(), ['body' => ['required', 'string', 'min:1', 'max:2000']]);
        if ($validator->fails()) {
            return $this->validationError($validator->errors()->toArray());
        }

        $message = DB::transaction(function () use ($request, $conversation, $validator) {
            $message = $conversation->messages()->create([
                'sender_type' => 'staff',
                'sender_id' => $request->user()->getAuthIdentifier(),
                'body' => trim($validator->validated()['body']),
            ]);
            $conversation->update([
                'assigned_staff_id' => $conversation->assigned_staff_id ?? $request->user()->getAuthIdentifier(),
                'last_message_at' => $message->created_at,
            ]);
            AuditLog::create([
                'actor_type' => 'staff',
                'actor_id' => $request->user()->getAuthIdentifier(),
                'action' => 'support.message_sent',
                'subject_type' => SupportConversation::class,
                'subject_id' => $conversation->id,
                'request_id' => $request->header('X-Request-Id', (string) Str::uuid()),
                'ip_hash' => hash('sha256', (string) $request->ip()),
                'metadata' => ['message_id' => $message->id],
            ]);
            return $message;
        });

        return response()->json(['data' => $this->messagePayload($message)], 201);
    }

    public function staffUpdateStatus(Request $request, int $conversationId): JsonResponse
    {
        $validator = Validator::make($request->all(), ['status' => ['required', 'in:open,closed']]);
        if ($validator->fails()) {
            return $this->validationError($validator->errors()->toArray());
        }

        $conversation = SupportConversation::findOrFail($conversationId);
        $conversation->update(['status' => $validator->validated()['status']]);

        AuditLog::create([
            'actor_type' => 'staff',
            'actor_id' => $request->user()->getAuthIdentifier(),
            'action' => 'support.conversation_status_updated',
            'subject_type' => SupportConversation::class,
            'subject_id' => $conversation->id,
            'request_id' => $request->header('X-Request-Id', (string) Str::uuid()),
            'ip_hash' => hash('sha256', (string) $request->ip()),
            'metadata' => ['status' => $conversation->status],
        ]);

        return response()->json(['data' => $conversation->fresh()->load('customer')]);
    }

    private function conversationPayload(SupportConversation $conversation): array
    {
        return [
            'id' => $conversation->id,
            'status' => $conversation->status,
            'customer_mobile' => $conversation->customer?->mobile,
            'last_message_at' => $conversation->last_message_at,
            'messages' => $conversation->messages->map(fn ($message) => $this->messagePayload($message)),
        ];
    }

    private function messagePayload(SupportMessage $message): array
    {
        return [
            'id' => $message->id,
            'sender_type' => $message->sender_type,
            'body' => $message->body,
            'created_at' => $message->created_at,
        ];
    }

    private function validationError(array $fields): JsonResponse
    {
        return response()->json(['error' => [
            'code' => 'VALIDATION_ERROR',
            'message' => 'اطلاعات ارسالی معتبر نیست.',
            'fields' => $fields,
        ]], 422);
    }
}

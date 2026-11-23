<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\SupportConversation;
use App\Models\SupportMessage;
use App\Services\Support\SupportAssistant;
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

        $this->appendAssistantReply($conversation, $validator->validated()['body']);
        $conversation->load(['customer', 'messages']);

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

        $this->appendAssistantReply($conversation, $validator->validated()['body']);

        return response()->json(['data' => $this->messagePayload($message)], 201);
    }

    /**
     * Start or continue an anonymous support conversation using an installation
     * secret. Only its SHA-256 digest is persisted; the raw secret stays on-device.
     */
    public function guestStart(Request $request): JsonResponse
    {
        $token = $this->guestToken($request);
        if ($token === null) {
            return $this->guestUnauthorized();
        }

        $validator = Validator::make($request->all(), [
            'body' => ['required', 'string', 'min:1', 'max:2000'],
        ]);
        if ($validator->fails()) {
            return $this->validationError($validator->errors()->toArray());
        }

        $tokenHash = hash('sha256', $token);
        $conversation = DB::transaction(function () use ($tokenHash, $validator) {
            $conversation = SupportConversation::query()
                ->whereNull('customer_id')
                ->where('guest_token_hash', $tokenHash)
                ->where('status', 'open')
                ->latest('last_message_at')
                ->lockForUpdate()
                ->first();

            if (! $conversation) {
                $conversation = SupportConversation::create([
                    'customer_id' => null,
                    'guest_token_hash' => $tokenHash,
                    'status' => 'open',
                ]);
            }

            $message = $conversation->messages()->create([
                'sender_type' => 'customer',
                'sender_id' => null,
                'body' => trim($validator->validated()['body']),
            ]);
            $conversation->update(['last_message_at' => $message->created_at]);

            return $conversation->load('messages');
        });

        $this->appendAssistantReply($conversation, $validator->validated()['body']);
        $conversation->load('messages');

        return response()->json(['data' => [
            'id' => $conversation->id,
            'status' => $conversation->status,
            'guest' => true,
            'last_message_at' => $conversation->last_message_at,
            'messages' => $conversation->messages->map(fn ($message) => $this->messagePayload($message)),
        ]], 201);
    }

    public function guestMessages(Request $request, int $conversationId): JsonResponse
    {
        $conversation = $this->findGuestConversation($request, $conversationId);
        if (! $conversation) {
            return $this->guestUnauthorized();
        }

        $messages = $conversation->messages()->orderBy('id')->get();
        $conversation->messages()
            ->where('sender_type', 'staff')
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json(['data' => $messages->map(fn ($message) => $this->messagePayload($message))]);
    }

    public function guestSend(Request $request, int $conversationId): JsonResponse
    {
        $conversation = $this->findGuestConversation($request, $conversationId);
        if (! $conversation) {
            return $this->guestUnauthorized();
        }
        if ($conversation->status !== 'open') {
            return response()->json(['error' => ['code' => 'CONVERSATION_CLOSED', 'message' => 'این گفت‌وگو بسته شده است.']], 409);
        }

        $validator = Validator::make($request->all(), [
            'body' => ['required', 'string', 'min:1', 'max:2000'],
        ]);
        if ($validator->fails()) {
            return $this->validationError($validator->errors()->toArray());
        }

        $message = DB::transaction(function () use ($conversation, $validator) {
            $message = $conversation->messages()->create([
                'sender_type' => 'customer',
                'sender_id' => null,
                'body' => trim($validator->validated()['body']),
            ]);
            $conversation->update(['last_message_at' => $message->created_at]);
            return $message;
        });

        $this->appendAssistantReply($conversation, $validator->validated()['body']);

        return response()->json(['data' => $this->messagePayload($message)], 201);
    }

    private function appendAssistantReply(SupportConversation $conversation, string $customerMessage): void
    {
        $lastAssistant = $conversation->messages()
            ->where('sender_type', 'assistant')
            ->latest('id')
            ->first();
        $mobile = $this->extractIranianMobile($customerMessage);

        $normalizedMessage = strtr($customerMessage, ['ي' => 'ی', 'ك' => 'ک', '‌' => ' ']);
        $isMissingRequirementFollowup = $lastAssistant !== null
            && str_contains($lastAssistant->body, 'راه‌های رسیدن به خدا زیاده!')
            && preg_match('/چطوری|چطور|چه راهکاری|یعنی چی|از چه راهی/u', $normalizedMessage) === 1;

        if ($mobile !== null && $lastAssistant !== null && str_contains($lastAssistant->body, 'شماره تماس')) {
            $conversation->update(['contact_mobile' => $mobile]);
            $answer = 'شماره تماس شما با موفقیت دریافت شد. درخواست پیگیری انسانی در این گفت‌وگو ثبت شد و کارشناس می‌تواند از طریق همین اطلاعات با شما تماس بگیرد.';
        } elseif ($isMissingRequirementFollowup) {
            $answer = (string) config('support_assistant.missing_requirement_response');
        } else {
            // Keep the recent customer context so follow-up answers don't ask for
            // an activity that the customer already named (e.g. real estate).
            $recentCustomerMessages = $conversation->messages()
                ->where('sender_type', 'customer')
                ->latest('id')
                ->limit(6)
                ->pluck('body')
                ->reverse()
                ->values()
                ->all();
            $contextText = implode("\n", $recentCustomerMessages);
            $normalizedContext = strtr(mb_strtolower($contextText, 'UTF-8'), ['ي' => 'ی', 'ك' => 'ک', '‌' => ' ']);
            $isGuildConversation = preg_match('/جواز کسب|پروانه کسب|مجوز صنفی|مجوز کسب/u', $normalizedContext) === 1;
            $assistantInput = $isGuildConversation ? $contextText : $customerMessage;
            $answer = app(SupportAssistant::class)->reply($assistantInput, $conversation->id);
        }

        $reply = $conversation->messages()->create([
            'sender_type' => 'assistant',
            'sender_id' => null,
            'body' => $answer,
        ]);
        $conversation->update(['last_message_at' => $reply->created_at]);
    }

    private function extractIranianMobile(string $message): ?string
    {
        $digits = strtr($message, [
            '۰' => '0', '۱' => '1', '۲' => '2', '۳' => '3', '۴' => '4',
            '۵' => '5', '۶' => '6', '۷' => '7', '۸' => '8', '۹' => '9',
            '٠' => '0', '١' => '1', '٢' => '2', '٣' => '3', '٤' => '4',
            '٥' => '5', '٦' => '6', '٧' => '7', '٨' => '8', '٩' => '9',
        ]);

        if (preg_match('/(?:\\+?98|0098|0)?9\\d{9}/', $digits, $matches) !== 1) {
            return null;
        }

        $mobile = preg_replace('/\\D/', '', $matches[0]) ?? '';
        if (str_starts_with($mobile, '0098')) {
            $mobile = '0'.substr($mobile, 4);
        } elseif (str_starts_with($mobile, '98')) {
            $mobile = '0'.substr($mobile, 2);
        } elseif (str_starts_with($mobile, '9')) {
            $mobile = '0'.$mobile;
        }

        return preg_match('/^09\\d{9}$/', $mobile) === 1 ? $mobile : null;
    }

    private function findGuestConversation(Request $request, int $conversationId): ?SupportConversation
    {
        $token = $this->guestToken($request);
        if ($token === null) {
            return null;
        }

        return SupportConversation::query()
            ->whereNull('customer_id')
            ->where('guest_token_hash', hash('sha256', $token))
            ->find($conversationId);
    }

    private function guestToken(Request $request): ?string
    {
        $token = $request->header('X-Support-Guest-Token');
        return is_string($token) && preg_match('/^[a-f0-9]{64}$/', $token) === 1
            ? $token
            : null;
    }

    private function guestUnauthorized(): JsonResponse
    {
        return response()->json(['error' => [
            'code' => 'INVALID_GUEST_TOKEN',
            'message' => 'شناسه امن گفت‌وگو معتبر نیست. لطفاً گفت‌وگوی جدیدی آغاز کنید.',
        ]], 401);
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

<?php

namespace App\Http\Controllers;

use App\Models\SupportConversation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class StaffPortalController extends Controller
{
    public function loginForm()
    {
        if (Auth::guard('staff')->check()) {
            return redirect()->route('staff.portal.index');
        }

        return view('staff.login');
    }

    public function authenticate(Request $request)
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $credentials['is_active'] = true;

        if (! Auth::guard('staff')->attempt($credentials)) {
            throw ValidationException::withMessages([
                'email' => 'ایمیل یا گذرواژه معتبر نیست یا حساب کاربری غیرفعال است.',
            ]);
        }

        $request->session()->regenerate();

        return redirect()->intended(route('staff.portal.index'));
    }

    public function index(Request $request)
    {
        $status = $request->query('status', 'open');
        $query = SupportConversation::query()
            ->with('customer')
            ->withCount('messages')
            ->orderByDesc('last_message_at');

        if (in_array($status, ['open', 'closed'], true)) {
            $query->where('status', $status);
        }

        return view('staff.portal', [
            'conversations' => $query->paginate(30)->withQueryString(),
            'selected' => null,
            'messages' => collect(),
            'status' => $status,
        ]);
    }

    public function show(Request $request, int $conversationId)
    {
        $conversation = SupportConversation::query()
            ->with(['customer', 'messages'])
            ->findOrFail($conversationId);

        $conversation->messages()
            ->where('sender_type', 'customer')
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        $status = $request->query('status', $conversation->status);

        return view('staff.portal', [
            'conversations' => SupportConversation::query()
                ->with('customer')
                ->withCount('messages')
                ->orderByDesc('last_message_at')
                ->paginate(30)
                ->withQueryString(),
            'selected' => $conversation,
            'messages' => $conversation->messages,
            'status' => $status,
        ]);
    }

    public function reply(Request $request, int $conversationId)
    {
        $data = $request->validate([
            'body' => ['required', 'string', 'min:1', 'max:2000'],
        ]);

        DB::transaction(function () use ($request, $conversationId, $data): void {
            $conversation = SupportConversation::query()->lockForUpdate()->findOrFail($conversationId);
            abort_if($conversation->status !== 'open', 409, 'این گفت‌وگو بسته شده است.');

            $message = $conversation->messages()->create([
                'sender_type' => 'staff',
                'sender_id' => Auth::guard('staff')->id(),
                'body' => trim($data['body']),
            ]);

            $conversation->update([
                'assigned_staff_id' => $conversation->assigned_staff_id ?? Auth::guard('staff')->id(),
                'last_message_at' => $message->created_at,
            ]);
        });

        return redirect()->route('staff.portal.show', $conversationId);
    }

    public function updateStatus(Request $request, int $conversationId)
    {
        $data = $request->validate(['status' => ['required', 'in:open,closed']]);
        SupportConversation::query()->whereKey($conversationId)->update(['status' => $data['status']]);

        return redirect()->route('staff.portal.show', $conversationId);
    }

    public function logout(Request $request)
    {
        Auth::guard('staff')->logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('staff.portal.login');
    }
}

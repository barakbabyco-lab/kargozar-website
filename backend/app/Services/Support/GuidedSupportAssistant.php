<?php

namespace App\Services\Support;

use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\SupportConversation;
use Illuminate\Support\Facades\Cache;

/**
 * Adds provider-independent guided flows and a KarGozar domain boundary
 * ahead of the existing reviewed FAQ/service knowledge.
 */
class GuidedSupportAssistant extends SupportAssistant
{
    public function reply(string $message, ?int $conversationId = null): string
    {
        $guidedReply = app(GuidedServiceFlowEngine::class)->handle($message, $conversationId);
        if ($guidedReply !== null) {
            app(UnansweredQuestionTracker::class)->record($message, 'guided_service_flow', $conversationId);

            return $guidedReply;
        }

        if ($conversationId !== null && $this->requestsInternalReview($conversationId)) {
            return $this->registerInternalReview($conversationId);
        }

        if ($conversationId !== null && ! $this->isInScope($message, $conversationId)) {
            app(UnansweredQuestionTracker::class)->record($message, 'out_of_scope', $conversationId);

            return 'من دستیار تخصصی کارگزارم و برای راهنمایی درباره خدمات راه‌اندازی، مجوزها، ثبت، امور اداری و توسعه کسب‌وکار طراحی شدم. اگر موضوعتون به این حوزه‌ها مربوطه، بفرمایید تا مسیر مناسب رو پیدا کنیم.';
        }

        if ($conversationId !== null && preg_match('/^(حالت چطوره|خوبی|چه خبر|چطوری|چطوره)[؟?!. ]*$/u', $this->normalize($message)) === 1) {
            return 'ممنون، آماده‌ام. بفرمایید درباره کدوم خدمت یا موضوع کسب‌وکارتون راهنمایی می‌خواید؟';
        }

        return parent::reply($message, $conversationId);
    }


    private function requestsInternalReview(int $conversationId): bool
    {
        $latest = SupportConversation::query()
            ->find($conversationId)?->messages()
            ->where('sender_type', 'customer')
            ->latest('id')
            ->value('body');

        if (! is_string($latest) || $latest === '') {
            return false;
        }

        $text = $this->normalize($latest);
        if (preg_match('/نمی ?خوام|نمی ?خواهم|نیازی ندارم/u', $text) === 1) {
            return false;
        }

        return preg_match('/تماس با کارشناس|تماس کارشناس|کارشناس انسانی|پیگیری انسانی/u', $text) === 1;
    }

    private function registerInternalReview(int $conversationId): string
    {
        $conversation = SupportConversation::query()->find($conversationId);
        if ($conversation !== null) {
            $context = is_array($conversation->assistant_context) ? $conversation->assistant_context : [];
            $context['internal_review'] = [
                'required' => true,
                'requested_at' => now()->toISOString(),
            ];
            $conversation->forceFill(['assistant_context' => $context])->save();
        }

        app(UnansweredQuestionTracker::class)->record(
            'درخواست بررسی داخلی توسط مشتری',
            'internal_review_requested',
            $conversationId
        );

        return 'درخواست شما برای بررسی داخلی ثبت شد. پیگیری از همین گفت‌وگو ادامه پیدا می‌کند؛ نیازی به ثبت شماره تماس نیست.';
    }

    private function isInScope(string $message, int $conversationId): bool
    {
        $conversation = SupportConversation::query()->find($conversationId);
        $latest = $conversation?->messages()
            ->where('sender_type', 'customer')
            ->latest('id')
            ->value('body');

        $candidate = is_string($latest) && $latest !== '' && $this->isContextualReply($latest)
            ? $message
            : (is_string($latest) && $latest !== '' ? $latest : $message);
        $text = $this->normalize($candidate);

        $smallTalk = [
            'سلام', 'درود', 'وقت بخیر', 'صبح بخیر', 'عصر بخیر', 'شب بخیر',
            'ممنون', 'متشکرم', 'مرسی', 'سپاس', 'خداحافظ', 'خسته نباشید',
            'حالت چطوره', 'خوبی', 'چه خبر',
        ];
        $plainText = trim(preg_replace('/[؟?!.،]+$/u', '', $text) ?? $text);
        foreach ($smallTalk as $term) {
            if ($plainText === $this->normalize($term) || str_starts_with($plainText, $this->normalize($term).' ')) {
                return true;
            }
        }

        foreach ((array) config('support_assistant.faqs', []) as $faq) {
            foreach (($faq['keywords'] ?? []) as $keyword) {
                $needle = $this->normalize((string) $keyword);
                if ($needle !== '' && str_contains($text, $needle)) {
                    return true;
                }
            }
        }

        $domainTerms = [
            'کسب و کار', 'کسب‌وکار', 'کسبکار', 'مغازه', 'فروشگاه', 'راه اندازی',
            'راه‌اندازی', 'مجوز', 'جواز', 'پروانه', 'صنفی', 'ثبت برند', 'علامت تجاری',
            'ثبت شرکت', 'شرکت', 'کارت بازرگانی', 'کارت بهداشت', 'مالیات', 'اینماد',
            'درگاه پرداخت', 'قرارداد', 'حسابداری', 'فاکتور', 'حقوق و دستمزد',
            'مدیریت انبار', 'سرمایه گذاری', 'سرمایه‌گذاری', 'طرح توجیهی',
            'تلفن اینترنتی', 'پنل پیامک', 'استاندارد', 'اجاره نامه', 'اجاره‌نامه',
            'کد رهگیری', 'مشاور املاک', 'تولیدی', 'پرسنل', 'crm',
        ];
        foreach ($domainTerms as $term) {
            if (str_contains($text, $this->normalize($term))) {
                return true;
            }
        }

        $catalogTerms = Cache::remember('support-assistant:scope-terms:v1', now()->addMinutes(10), function (): array {
            $serviceTitles = Service::query()->where('is_active', true)->pluck('title')->all();
            $activeCategoryIds = ServiceCategory::activeHierarchyIds();
            $categoryTitles = $activeCategoryIds === []
                ? []
                : ServiceCategory::query()->whereIn('id', $activeCategoryIds)->pluck('name')->all();

            return array_values(array_unique(array_filter(array_merge($serviceTitles, $categoryTitles), 'is_string')));
        });

        foreach ($catalogTerms as $term) {
            $needle = $this->normalize((string) $term);
            if (mb_strlen($needle, 'UTF-8') >= 3 && str_contains($text, $needle)) {
                return true;
            }
        }

        return false;
    }

    private function isContextualReply(string $message): bool
    {
        return preg_match(
            '/^(بله|بلی|نه|خیر|اوکی|باشه|چشم|ممنون|مرسی|این|اون|آن|همین|چطور|چطوری|چقدر|مدارکش|شرایطش|مراحلش|بعدش|گزینه\s*\d+|[۰-۹]+|اولی|دومی|سومی)[؟?!. ]*$/u',
            $this->normalize($message)
        ) === 1;
    }

    private function normalize(string $value): string
    {
        $value = mb_strtolower($value, 'UTF-8');
        $value = strtr($value, ['ي' => 'ی', 'ك' => 'ک', '‌' => ' ', 'ۀ' => 'ه']);
        $value = preg_replace('/\s+/u', ' ', $value) ?? $value;

        return trim($value);
    }
}

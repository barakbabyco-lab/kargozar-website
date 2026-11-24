<?php

namespace App\Services\Support;

use App\Models\Service;
class SupportAssistant
{
    /**
     * Prefer structured service knowledge and FAQs; search the public web for safe unknowns.
     * Sensitive or legally consequential questions remain routed to a human.
     */
    public function reply(string $message, ?int $conversationId = null): string
    {
        $text = $this->normalize($message);

        foreach ((array) config('support_assistant.human_request_terms', []) as $term) {
            if (is_string($term) && $term !== '' && str_contains($text, $this->normalize($term))) {
                app(UnansweredQuestionTracker::class)->record($message, 'human_escalation', $conversationId);
                return (string) config('support_assistant.human_handoff_response', config('support_assistant.fallback'));
            }
        }

        // Case-specific legal disputes and explicit requests for a human remain
        // hard handoff paths even when the AI provider is enabled.
        foreach ((array) config('support_assistant.hard_escalation_terms', []) as $term) {
            if (is_string($term) && $term !== '' && str_contains($text, $this->normalize($term))) {
                app(UnansweredQuestionTracker::class)->record($message, 'human_escalation', $conversationId);
                return (string) config('support_assistant.fallback');
            }
        }

        // When the server-side model is configured, let it interpret the whole
        // turn before legacy keyword rules. This is what enables natural
        // language needs analysis and safe answers outside the service catalogue.
        if ((bool) config('assistant_ai.enabled', false)) {
            $serviceContext = $this->assistantServiceContext($message);
            $isShortAcknowledgement = preg_match('/^(سلام|درود|وقت بخیر|ممنون|متشکرم|مرسی|خداحافظ|خسته نباشید|بله|بلی|نه|خیر|اوکی|باشه|چشم|درسته)(\\s|[.!؟،]*)*$/u', $text) === 1;
            // Search is the default for substantive, non-sensitive questions,
            // including topics outside the Kargozar catalogue. This prevents
            // the assistant from relying only on model training data.
            $needsCurrentResearch = ! $isShortAcknowledgement;
            $sources = [];
            if ($needsCurrentResearch && (bool) config('support_assistant.web_search.enabled', true)) {
                $searchQuestion = $message;
                if (preg_match('/مغازه|فروشگاه|بوتیک|لباس فروشی|نجاری/u', $text) === 1
                    && preg_match('/جواز|پروانه|مجوز/u', $text) !== 1) {
                    $searchQuestion = 'شرایط و مجوزهای رسمی راه‌اندازی کسب‌وکار برای: '.$message;
                }
                $serviceKeys = array_values(array_unique(array_filter(array_column($serviceContext, 'service_key'), 'is_string')));
                $webResult = app(WebSearchService::class)->search($searchQuestion, $serviceKeys);
                $sources = is_array($webResult) && is_array($webResult['sources'] ?? null)
                    ? $webResult['sources']
                    : [];
                if ($sources !== []) {
                    $sources = app(WebPageContentService::class)->enrich($sources);
                }
            }

            if ($serviceContext !== []) {
                $analysis = app(AssistantLanguageModel::class)->analyzeServiceNeed(
                    $message,
                    $conversationId,
                    $sources,
                    $serviceContext,
                );

                if ($analysis !== null) {
                    if (($analysis['needs_human'] ?? false) === true) {
                        app(UnansweredQuestionTracker::class)->record($message, 'human_escalation', $conversationId);
                        return (string) config('support_assistant.human_handoff_response', config('support_assistant.fallback'));
                    }

                    if (is_string($analysis['clarifying_question'] ?? null) && $analysis['clarifying_question'] !== '') {
                        app(UnansweredQuestionTracker::class)->record($message, 'service_clarification', $conversationId);
                        return $analysis['clarifying_question'];
                    }

                    $selectedServiceKeys = array_values(array_unique(array_merge(
                        $analysis['matched_service_keys'] ?? [],
                        $analysis['required_service_keys'] ?? [],
                    )));
                    if ($selectedServiceKeys !== []) {
                        $serviceContext[] = [
                            'service_quote_context' => app(ServiceQuoteBuilder::class)->build($selectedServiceKeys),
                        ];
                    }

                    $serviceContext[] = ['service_need_analysis' => $analysis];
                }
            }

            $aiAnswer = app(AssistantLanguageModel::class)->answer(
                $message,
                $conversationId,
                $sources,
                $serviceContext,
            );

            if ($aiAnswer !== null) {
                if ($sources !== []) {
                    $aiAnswer .= "\n\nمنابع اولیه برای بررسی:";
                    foreach (array_slice($sources, 0, 5) as $index => $source) {
                        $url = trim((string) ($source['url'] ?? ''));
                        if (str_starts_with(strtolower($url), 'https://')) {
                            $title = trim((string) ($source['title'] ?? 'منبع وب'));
                            $aiAnswer .= "\n".($index + 1).'. '.$title.' — '.$url;
                        }
                    }
                }

                app(UnansweredQuestionTracker::class)->record($message, 'ai_answered', $conversationId);
                return $aiAnswer;
            }
        }

        foreach (config('support_assistant.missing_requirement_phrases', []) as $phrase) {
            if ($phrase !== '' && str_contains($text, $this->normalize($phrase))) {
                app(UnansweredQuestionTracker::class)->record($message, 'human_escalation', $conversationId);
                return (string) config('support_assistant.missing_requirement_response', config('support_assistant.fallback'));
            }
        }

        foreach (config('support_assistant.escalation_terms', []) as $term) {
            if ($term !== '' && str_contains($text, $this->normalize($term))) {
                app(UnansweredQuestionTracker::class)->record($message, 'human_escalation', $conversationId);
                return (string) config('support_assistant.fallback');
            }
        }

        $guildAnswer = $this->guildLicenseReply($text);
        if ($guildAnswer !== null) {
            return $guildAnswer;
        }

        $knowledgeAnswer = $this->knowledgeServiceReply($text);
        if ($knowledgeAnswer !== null) {
            return $knowledgeAnswer;
        }

        $best = null;
        $bestScore = 0.0;
        $secondScore = 0.0;

        foreach (config('support_assistant.faqs', []) as $faq) {
            $keywords = $faq['keywords'] ?? [];
            if ($keywords === []) {
                continue;
            }

            $matched = 0;
            foreach ($keywords as $keyword) {
                $needle = $this->normalize($keyword);
                if ($needle !== '' && str_contains($text, $needle)) {
                    $matched++;
                }
            }

            $score = $matched / count($keywords);
            if ($score > $bestScore) {
                $secondScore = $bestScore;
                $bestScore = $score;
                $best = $faq;
            } elseif ($score > $secondScore) {
                $secondScore = $score;
            }
        }

        $threshold = (float) config('support_assistant.confidence_threshold', 0.5);
        $margin = (float) config('support_assistant.minimum_score_margin', 0.15);

        if ($best !== null && $bestScore >= $threshold && ($bestScore - $secondScore) >= $margin) {
            $answer = (string) ($best['answer'] ?? '');
            return $answer;
        }

        $dateTimeAnswer = $this->currentDateTimeReply($text);
        if ($dateTimeAnswer !== null) {
            return $dateTimeAnswer;
        }

        $webAnswer = $this->publicWebReply($message, $conversationId);
        if ($webAnswer !== null) {
            $noResult = (string) config('support_assistant.web_search.no_result', '');
            $outcome = $noResult !== '' && str_starts_with($webAnswer, $noResult)
                ? 'web_no_result'
                : (str_contains($webAnswer, 'منابع برای بررسی بیشتر:') ? 'web_answered' : 'no_answer');
            app(UnansweredQuestionTracker::class)->record($message, $outcome, $conversationId);
            return $webAnswer;
        }

        $modelAnswer = app(AssistantLanguageModel::class)->answer(
            $message,
            $conversationId,
            [],
            $this->assistantServiceContext($message),
        );
        if ($modelAnswer !== null) {
            app(UnansweredQuestionTracker::class)->record($message, 'ai_answered', $conversationId);
            return $modelAnswer;
        }

        app(UnansweredQuestionTracker::class)->record($message, 'no_answer', $conversationId);
        return (string) config('support_assistant.fallback');
    }

    /**
     * Return the live Tehran date/time on demand, using the Persian calendar.
     */
    private function currentDateTimeReply(string $text): ?string
    {
        $dateTimeTerms = [
            'ساعت چند', 'ساعت چنده', 'الان ساعت', 'الان چه ساعتی',
            'تاریخ امروز', 'تاریخ و ساعت', 'تاریخ شمسی امروز', 'امروز تاریخ چنده',
            'الان تاریخ چنده', 'امروز چندمه', 'امروز چه روز', 'امروز چند شنبه',
            'چه روزیه', 'الان چندمه',
            'time now', 'current date', 'what time is it',
        ];
        $asksDateTime = false;
        foreach ($dateTimeTerms as $term) {
            if (str_contains($text, $term)) {
                $asksDateTime = true;
                break;
            }
        }
        if (! $asksDateTime) {
            return null;
        }

        $now = now((string) config('support_assistant.timezone', 'Asia/Tehran'));
        $gy = (int) $now->format('Y');
        $gm = (int) $now->format('n');
        $gd = (int) $now->format('j');
        $gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
        $gy2 = $gm > 2 ? $gy + 1 : $gy;
        $days = 355666 + (365 * $gy) + intdiv($gy2 + 3, 4) - intdiv($gy2 + 99, 100)
            + intdiv($gy2 + 399, 400) + $gd + $gdm[$gm - 1];
        $jy = -1595 + (33 * intdiv($days, 12053));
        $days %= 12053;
        $jy += 4 * intdiv($days, 1461);
        $days %= 1461;
        if ($days > 365) {
            $jy += intdiv($days - 1, 365);
            $days = ($days - 1) % 365;
        }
        if ($days < 186) {
            $jm = 1 + intdiv($days, 31);
            $jd = 1 + ($days % 31);
        } else {
            $jm = 7 + intdiv($days - 186, 30);
            $jd = 1 + (($days - 186) % 30);
        }

        $months = [1 => 'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'];
        $weekdays = ['یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه'];
        $date = $weekdays[(int) $now->format('w')].'، '.$jd.' '.$months[$jm].' '.$jy;
        $time = $now->format('H:i:s');
        $digits = ['0' => '۰', '1' => '۱', '2' => '۲', '3' => '۳', '4' => '۴', '5' => '۵', '6' => '۶', '7' => '۷', '8' => '۸', '9' => '۹'];
        $date = strtr($date, $digits);
        $time = strtr($time, $digits);

        return 'تاریخ و ساعت فعلی تهران: '.$date.'، ساعت '.$time.' (منطقه زمانی Asia/Tehran).';
    }

    /**
     * Use public web search only after the internal service registry and FAQ miss.
     * Sensitive questions are intercepted earlier and never reach this method.
     */
    private function publicWebReply(string $question, ?int $conversationId = null): ?string
    {
        if (! (bool) config('support_assistant.web_search.enabled', true)) {
            return null;
        }

        $result = app(WebSearchService::class)->search($question);
        if (! is_array($result)) {
            return app(AssistantLanguageModel::class)->answer($question, $conversationId, [], $this->assistantServiceContext($question))
                ?? ((string) config('support_assistant.web_search.no_result', '') ?: null);
        }

        $sources = $result['sources'] ?? [];
        $answer = trim((string) ($result['answer'] ?? ''));
        if ($answer === '') {
            $answer = 'چند نتیجه جست‌وجو پیدا شد، اما فقط خلاصه‌های کوتاه نتایج در دسترس است و متن کامل صفحات هنوز بررسی نشده است.';
        }

        $modelAnswer = app(AssistantLanguageModel::class)->answer(
            $question,
            $conversationId,
            is_array($sources) ? $sources : [],
            $this->assistantServiceContext($question),
        );
        if ($modelAnswer !== null) {
            $answer = $modelAnswer;
        }

        $response = (string) config('support_assistant.web_search.fallback_intro', '')."\n\n".$answer;
        $sources = $result['sources'] ?? [];
        if (is_array($sources) && $sources !== []) {
            $response .= "\n\nمنابع برای بررسی بیشتر:";
            foreach ($sources as $index => $source) {
                $title = trim((string) ($source['title'] ?? 'منبع وب'));
                $url = trim((string) ($source['url'] ?? ''));
                if ($url !== '') {
                    $snippet = trim((string) ($source['snippet'] ?? ''));
                    $response .= "\n".($index + 1).'. '.$title.' — '.$url;
                    if ($snippet !== '') {
                        $response .= "\n   ".$snippet;
                    }
                }
            }
        }

        return $response;
    }

    /**
     * Provide a small, relevant slice of the service catalogue to the model.
     * The model may explain these records but cannot invent catalogue entries.
     */
    private function assistantServiceContext(string $question): array
    {
        $context = [];
        $registryPath = resource_path('knowledge/service_knowledge_registry.json');
        if (is_file($registryPath)) {
            $registry = json_decode((string) file_get_contents($registryPath), true);
            foreach (($registry['categories'] ?? []) as $category) {
                $file = $category['knowledge_file'] ?? null;
                if (! is_string($file) || $file === '') {
                    continue;
                }

                $path = resource_path('knowledge/'.$file);
                if (! is_file($path)) {
                    continue;
                }

                $document = json_decode((string) file_get_contents($path), true);
                foreach (($document['services'] ?? []) as $record) {
                    if (! is_array($record)) {
                        continue;
                    }

                    $title = $this->normalize((string) ($record['title'] ?? ''));
                    $questionText = $this->normalize($question);
                    $tokens = preg_split('/\s+/u', $title, -1, PREG_SPLIT_NO_EMPTY) ?: [];
                    $tokens = array_values(array_filter($tokens, fn ($token) => mb_strlen($token, 'UTF-8') >= 3));
                    $score = 0;
                    foreach ($tokens as $token) {
                        if (str_contains($questionText, $token)) {
                            $score++;
                        }
                    }

                    if ($title !== '' && str_contains($questionText, $title)) {
                        $score += 3;
                    }

                    if ($score < 1) {
                        continue;
                    }

                    $serviceKey = (string) ($record['service_key'] ?? '');
                    $route = $serviceKey !== '' ? config('knowledge_sources.services.'.$serviceKey, []) : [];
                    $liveSourceKey = is_array($route) ? ($route['live_verification_source'] ?? null) : null;
                    $liveSource = is_string($liveSourceKey) ? config('knowledge_sources.sources.'.$liveSourceKey, []) : [];
                    $recordOfficialSource = trim((string) ($record['official_source'] ?? ''));
                    $recordSourceUrl = trim((string) ($record['source_url'] ?? ''));
                    $liveSourceName = is_array($liveSource) ? trim((string) ($liveSource['name'] ?? '')) : '';
                    $liveSourceUrl = is_array($liveSource) ? trim((string) ($liveSource['base_url'] ?? '')) : '';

                    $context[] = [
                        'category' => $category['title'] ?? null,
                        'service_key' => $record['service_key'] ?? null,
                        'title' => $record['title'] ?? null,
                        'record_status' => $record['status'] ?? 'needs_review',
                        'scope' => $record['scope'] ?? null,
                        'what_is_it' => $record['what_is_it'] ?? null,
                        'eligibility' => $record['eligibility'] ?? null,
                        'conditions' => $record['conditions'] ?? [],
                        'documents' => $record['documents'] ?? [],
                        'steps' => $record['steps'] ?? [],
                        'fees' => $record['fees'] ?? null,
                        'issuance_time' => $record['issuance_time'] ?? null,
                        'issuing_authority' => $record['issuing_authority'] ?? null,
                        'official_source' => $recordOfficialSource !== '' ? $recordOfficialSource : ($liveSourceName !== '' ? $liveSourceName : null),
                        'source_url' => $recordSourceUrl !== '' ? $recordSourceUrl : ($liveSourceUrl !== '' ? $liveSourceUrl : null),
                        'verification_status' => $record['verification_status'] ?? 'needs_review',
                        'catalogue_category' => $category['title'] ?? null,
                        '_match_score' => $score,
                    ];
                }
            }
        }

        usort($context, fn ($left, $right) => ($right['_match_score'] ?? 0) <=> ($left['_match_score'] ?? 0));
        $context = array_slice($context, 0, 4);
        foreach ($context as &$record) {
            unset($record['_match_score']);
        }
        unset($record);

        $normalizedQuestion = $this->normalize($question);

        $intentHints = [
            'company-registration' => ['pattern' => '/ثبت شرکت|تاسیس شرکت|تأسیس شرکت|شرکت حقوقی بزنم|شرکت بزنم|شرکت سهامی خاص|شرکت با مسئولیت محدود|مسئولیت محدود ثبت/u', 'title' => 'ثبت شرکت و انتخاب قالب حقوقی'],
            'company-changes' => ['pattern' => '/ثبت تغییرات شرکت|تغییر مدیران شرکت|افزایش سرمایه شرکت|تغییر آدرس شرکت/u', 'title' => 'ثبت تغییرات شرکت'],
            'company-dissolution' => ['pattern' => '/انحلال شرکت|تعطیلی شرکت حقوقی/u', 'title' => 'انحلال و تصفیه شرکت'],
            'trademark-registration' => ['pattern' => '/ثبت برند|برند.*ثبت|ثبت.*برند|ثبت علامت تجاری|علامت تجاری|ثبت نام تجاری/u', 'title' => 'ثبت علامت تجاری و برند'],
            'logo-registration' => ['pattern' => '/ثبت لوگو|لوگو را ثبت|علامت تصویری/u', 'title' => 'ثبت لوگو به‌عنوان علامت'],
            'industrial-design-registration' => ['pattern' => '/ثبت طرح صنعتی|ثبت ظاهر محصول/u', 'title' => 'ثبت طرح صنعتی'],
            'invention-registration' => ['pattern' => '/ثبت اختراع|گواهی اختراع/u', 'title' => 'ثبت اختراع'],
            'business-account-opening' => ['pattern' => '/افتتاح حساب|حساب جاری شرکتی|حساب تجاری/u', 'title' => 'افتتاح حساب جاری و حساب تجاری'],
            'lease-tracking-code' => ['pattern' => '/کد رهگیری اجاره|اجاره نامه.*کد رهگیری|اجاره‌نامه.*کد رهگیری|ثبت قرارداد اجاره/u', 'title' => 'دریافت کد رهگیری اجاره‌نامه'],
            'health-card' => ['pattern' => '/کارت بهداشت|گواهی سلامت شاغل/u', 'title' => 'کارت بهداشت و گواهی سلامت شاغلان'],
            'environment-health-approval' => ['pattern' => '/تاییدیه بهداشت محیط|تأییدیه بهداشت محیط/u', 'title' => 'تأییدیه بهداشت محیط'],
            'trade-law-training-certificate' => ['pattern' => '/احکام تجارت|گواهی احکام کسب|دوره احکام تجارت/u', 'title' => 'گواهی دوره احکام تجارت و کسب‌وکار'],
            'national-standards-approval' => ['pattern' => '/نشان استاندارد|گواهی استاندارد|استاندارد محصول/u', 'title' => 'تأییدیه‌ها و نشان استاندارد'],
            'enamad' => ['pattern' => '/اینماد|نماد اعتماد الکترونیکی/u', 'title' => 'دریافت و تمدید اینماد'],
            'business-website' => ['pattern' => '/سایت فروشگاهی|وب سایت فروشگاهی|وب‌سایت فروشگاهی|طراحی سایت شرکتی/u', 'title' => 'طراحی و راه‌اندازی وب‌سایت'],
            'payment-gateway' => ['pattern' => '/درگاه پرداخت اینترنتی|درگاه پرداخت/u', 'title' => 'درگاه پرداخت اینترنتی'],
            'employment-contract' => ['pattern' => '/قرارداد کار|قرارداد استخدام|قرارداد پرسنل/u', 'title' => 'تنظیم قرارداد کار'],
            'contractor-agreement' => ['pattern' => '/قرارداد پیمانکاری|قرارداد پیمانکار/u', 'title' => 'تنظیم قرارداد پیمانکاری'],
            'accounting-software' => ['pattern' => '/نرم افزار حسابداری|نرم‌افزار حسابداری/u', 'title' => 'نرم‌افزار حسابداری و مالی'],
            'payroll-hr' => ['pattern' => '/حقوق و دستمزد|نرم افزار حقوق|نرم‌افزار حقوق/u', 'title' => 'حقوق و دستمزد و مدیریت پرسنل'],
            'crm' => ['pattern' => '/مدیریت ارتباط با مشتری|سیستم crm|\bcrm\b/iu', 'title' => 'مدیریت ارتباط با مشتریان'],
            'inventory-management' => ['pattern' => '/مدیریت انبار|نرم افزار انبار|نرم‌افزار انبار/u', 'title' => 'مدیریت انبار و موجودی'],
            'feasibility-study' => ['pattern' => '/طرح توجیهی|امکان سنجی|امکان‌سنجی/u', 'title' => 'طرح توجیهی و امکان‌سنجی'],
            'business-plan' => ['pattern' => '/بیزینس پلن|بیزنس پلن|طرح کسب و کار|طرح کسب‌وکار/u', 'title' => 'تهیه طرح کسب‌وکار'],
            'business-valuation' => ['pattern' => '/ارزش گذاری کسب و کار|ارزش‌گذاری کسب‌وکار/u', 'title' => 'ارزش‌گذاری کسب‌وکار'],
            'fundraising' => ['pattern' => '/جذب سرمایه گذار|جذب سرمایه‌گذار|تامین سرمایه|تأمین سرمایه/u', 'title' => 'تأمین سرمایه و جذب سرمایه‌گذار'],
        ];

        $existingServiceKeys = array_values(array_filter(array_column($context, 'service_key'), 'is_string'));
        foreach ($intentHints as $serviceKey => $hint) {
            if (in_array($serviceKey, $existingServiceKeys, true)
                || preg_match($hint['pattern'], $normalizedQuestion) !== 1) {
                continue;
            }

            $route = config('knowledge_sources.services.'.$serviceKey, []);
            $liveSourceKey = is_array($route) ? ($route['live_verification_source'] ?? null) : null;
            $source = is_string($liveSourceKey) ? config('knowledge_sources.sources.'.$liveSourceKey, []) : [];

            $context[] = [
                'service_key' => $serviceKey,
                'title' => $hint['title'],
                'intent_hint' => true,
                'verification_status' => 'requires_current_source_review',
                'official_source' => is_array($source) ? ($source['name'] ?? null) : null,
                'source_url' => is_array($source) ? ($source['base_url'] ?? null) : null,
            ];
        }

        if (preg_match('/مالیات|پرونده مالیاتی|کد رهگیری مالیاتی|شناسه مالیاتی/u', $normalizedQuestion) === 1) {
            $context[] = [
                'service_key' => 'tax-file-and-tracking',
                'title' => 'تشکیل پرونده و پیگیری امور مالیاتی',
                'verification_status' => 'needs_live_tax_portal_review',
                'official_source' => 'درگاه ملی خدمات الکترونیک سازمان امور مالیاتی',
                'source_url' => 'https://my.tax.gov.ir/',
            ];
        }

        if (preg_match('/جواز|پروانه|مجوز|مغازه|فروشگاه|بوتیک|لباس فروشی|نجاری|راه اندازی|راه‌اندازی|راه بندازی|راه بندازم/u', $normalizedQuestion) === 1) {
            $context[] = [
                'service_key' => 'guild-business-license',
                'title' => 'پروانه کسب و مجوزهای صنفی',
                'scope' => 'خدمت احتمالی مرتبط با راه‌اندازی یا اداره محل کسب؛ فقط پس از روشن‌شدن نوع فعالیت و محل، applicability را بررسی کن.',
                'verification_status' => 'needs_live_worksheet_retrieval',
                'official_source' => 'درگاه ملی مجوزهای کشور و کاربرگ جاری فعالیت',
                'source_url' => 'https://mojavez.ir/',
            ];
            $context[] = [
                'guild_activity_preflight' => $this->classifyGuildActivity($question),
                'note' => 'این طبقه‌بندی فقط پیش‌بررسی است؛ کاربرگ رسمی رسته و شهر مرجع نهایی است.',
            ];

            $mapPath = resource_path('knowledge/service_prerequisite_fulfillment_map.json');
            if (is_file($mapPath)) {
                $prerequisiteMap = json_decode((string) file_get_contents($mapPath), true);
                if (is_array($prerequisiteMap)) {
                    $context[] = [
                        'prerequisite_fulfillment_map' => $prerequisiteMap['rules'] ?? [],
                        'assistant_rules' => $prerequisiteMap['assistant_rules'] ?? [],
                        'mapping_status' => $prerequisiteMap['status'] ?? 'unknown',
                    ];
                }
            }
        }

        $catalogMappingPath = resource_path('knowledge/service_catalog_mapping.json');
        if (is_file($catalogMappingPath)) {
            $catalogMapping = json_decode((string) file_get_contents($catalogMappingPath), true);
            if (is_array($catalogMapping)) {
                $relevantServiceKeys = array_values(array_unique(array_filter(array_column($context, 'service_key'), 'is_string')));
                foreach ($context as $item) {
                    foreach (($item['prerequisite_fulfillment_map'] ?? []) as $rule) {
                        $mappedKey = $rule['fulfillment']['service_key'] ?? null;
                        if (is_string($mappedKey) && $mappedKey !== '') {
                            $relevantServiceKeys[] = $mappedKey;
                        }
                    }
                }
                $relevantServiceKeys = array_values(array_unique($relevantServiceKeys));

                $catalogEntries = array_values(array_filter(
                    is_array($catalogMapping['services'] ?? null) ? $catalogMapping['services'] : [],
                    fn ($entry) => is_array($entry)
                        && in_array($entry['service_key'] ?? null, $relevantServiceKeys, true)
                ));
                $mappedSlugs = array_values(array_unique(array_filter(array_map(
                    fn ($entry) => is_array($entry)
                        && in_array($entry['status'] ?? null, ['mapped_to_service_row', 'mapped_to_existing_related_service'], true)
                        ? ($entry['catalog_slug'] ?? null)
                        : null,
                    $catalogEntries
                ), 'is_string')));
                $activeSlugs = $mappedSlugs === []
                    ? []
                    : Service::query()->whereIn('slug', $mappedSlugs)->where('is_active', true)->pluck('slug')->all();

                $catalogEntries = array_map(function ($entry) use ($activeSlugs): array {
                    $mapped = in_array($entry['status'] ?? null, ['mapped_to_service_row', 'mapped_to_existing_related_service'], true);
                    $active = is_string($entry['catalog_slug'] ?? null)
                        && in_array($entry['catalog_slug'], $activeSlugs, true);

                    return array_merge($entry, [
                        'orderable' => $mapped && $active,
                        'availability_status' => ! $mapped
                            ? 'not_orderable_pending_catalogue_setup'
                            : ($active ? 'active_catalogue_row' : 'catalogue_row_missing_or_inactive'),
                    ]);
                }, $catalogEntries);

                $context[] = [
                    'service_catalog_mapping' => $catalogEntries,
                    'catalog_mapping_status' => $catalogMapping['status'] ?? 'unknown',
                    'catalog_mapping_note' => $catalogMapping['note'] ?? null,
                ];
            }
        }

        return $context;
    }

    /**
     * Answer common guild-license document questions using the shared checklist
     * plus the activity classifier. This is a preflight, not a universal legal list.
     */
    private function guildLicenseReply(string $text): ?string
    {
        $guildTerms = ['جواز کسب', 'پروانه کسب', 'مجوز صنفی', 'مجوز کسب'];
        $isGuildQuestion = false;
        foreach ($guildTerms as $term) {
            if (str_contains($text, $this->normalize($term))) {
                $isGuildQuestion = true;
                break;
            }
        }

        if (! $isGuildQuestion) {
            return null;
        }

        $asksRequirements = preg_match('/مدرک|مدارک|شرط|شرایط|لازم|نیاز|پیش نیاز/u', $text) === 1;
        if (! $asksRequirements) {
            $classification = $this->classifyGuildActivity($text);
            if (($classification['needs_clarification'] ?? true) === true) {
                return 'برای راهنمایی دقیق جواز کسب، لطفاً نوع شغل دقیق‌تون رو بفرمایید و بگید محل فعالیت در کدوم شهره؟';
            }

            return 'نوع فعالیت رو مشخص کردیم. برای تطبیق کاربرگ رسمی و شرایط همون رسته، لطفاً بفرمایید محل کسب در کدوم شهره؟';
        }

        $isRealEstate = preg_match('/مشاور املاک|املاک|بنگاه املاک/u', $text) === 1;
        $hasLegalPersonType = preg_match('/حقیقی|حقوقی/u', $text) === 1;
        if ($isRealEstate && ! $hasLegalPersonType) {
            return 'برای جواز مشاور املاک، اول باید مشخص کنیم درخواست به نام شخص حقیقیه یا شرکت (شخص حقوقی). شما می‌خواید جواز به نام خودتون صادر بشه یا به نام شرکت؟';
        }

        $classification = $this->classifyGuildActivity($text);
        $labels = $this->requirementDisplayLabels();
        $commonKeys = $classification['common_preflight'] ?? [];
        $specialKeys = $classification['requirements'] ?? [];
        $commonLabels = [];
        $specialLabels = [];

        foreach ($commonKeys as $key) {
            $label = $labels[$key] ?? config('support_assistant.customer_communication.document_labels.'.$key);
            if (is_string($label) && $label !== '') {
                $commonLabels[] = $label;
            }
        }
        foreach ($specialKeys as $key) {
            $label = $labels[$key] ?? config('support_assistant.customer_communication.document_labels.'.$key);
            if (is_string($label) && $label !== '') {
                $specialLabels[] = $label;
            }
        }

        $answer = "برای جواز کسب، اول این موارد رو به‌عنوان چک‌لیست اولیه بررسی می‌کنیم:\n";
        if ($commonLabels !== []) {
            $answer .= $this->formatItems(array_values(array_unique($commonLabels)));
        }

        if (($classification['needs_clarification'] ?? true) === true && $specialLabels === []) {
            return "برای جواز کسب، شرایط و مدارک به نوع دقیق فعالیت و شهر محل کسب بستگی داره. لطفاً اول نوع شغل دقیق‌تون رو بفرمایید و بگید محل کسب در کدوم شهره تا موارد مرتبط با همون فعالیت رو بررسی کنیم.";
        }

        if ($specialLabels !== []) {
            $answer .= "\n\nمدارک یا تأییدیه‌های مرتبط با این شغل هم ممکنه لازم باشه:\n";
            $answer .= $this->formatItems(array_values(array_unique($specialLabels)));
        }

        $answer .= "\n\nاین موارد راهنمای اولیه‌اند؛ فهرست نهایی باید با ضوابط رسته و شهر شما تطبیق داده بشه.";
        return $this->appendCustomerClosing($answer);
    }

    private function requirementDisplayLabels(): array
    {
        $path = resource_path('knowledge/shared_requirement_library.json');
        if (! is_file($path)) {
            return [];
        }

        $library = json_decode((string) file_get_contents($path), true);
        if (! is_array($library) || ! is_array($library['requirements'] ?? null)) {
            return [];
        }

        $labels = [];
        foreach ($library['requirements'] as $requirement) {
            $key = $requirement['requirement_key'] ?? null;
            $label = $requirement['customer_display_label'] ?? null;
            if (is_string($key) && is_string($label) && $label !== '') {
                $labels[$key] = $label;
            }
        }

        return $labels;
    }

    /**
     * Resolve a service against the registry and its category knowledge file.
     * This provides a concise first-pass answer from existing structured records.
     */
    private function knowledgeServiceReply(string $text): ?string
    {
        $registryPath = resource_path('knowledge/service_knowledge_registry.json');
        if (! is_file($registryPath)) {
            return null;
        }

        $registry = json_decode((string) file_get_contents($registryPath), true);
        if (! is_array($registry) || ! is_array($registry['categories'] ?? null)) {
            return null;
        }

        $best = null;
        $bestScore = 0;
        $secondScore = 0;

        foreach ($registry['categories'] as $category) {
            $file = $category['knowledge_file'] ?? null;
            if (! is_string($file) || $file === '') {
                continue;
            }

            $categoryPath = resource_path('knowledge/'.$file);
            if (! is_file($categoryPath)) {
                continue;
            }

            $knowledge = json_decode((string) file_get_contents($categoryPath), true);
            if (! is_array($knowledge) || ! is_array($knowledge['services'] ?? null)) {
                continue;
            }

            foreach (($category['services'] ?? []) as $registeredService) {
                $key = $registeredService['service_key'] ?? null;
                if (! is_string($key)) {
                    continue;
                }

                $record = null;
                foreach ($knowledge['services'] as $candidate) {
                    if (($candidate['service_key'] ?? null) === $key) {
                        $record = $candidate;
                        break;
                    }
                }
                if (! is_array($record)) {
                    continue;
                }

                $title = $this->normalize((string) ($record['title'] ?? $registeredService['title'] ?? ''));
                $tokens = preg_split('/\s+/u', $title, -1, PREG_SPLIT_NO_EMPTY) ?: [];
                $stopWords = ['و', 'در', 'از', 'به', 'با', 'برای', 'یا', 'بر', 'را', 'آن'];
                $tokens = array_values(array_unique(array_filter(
                    $tokens,
                    fn ($token) => ! in_array($token, $stopWords, true) && mb_strlen($token, 'UTF-8') >= 2
                )));

                $matchedTokens = array_filter($tokens, fn ($token) => str_contains($text, $token));
                $score = count($matchedTokens);
                foreach ($tokens as $index => $token) {
                    $next = $tokens[$index + 1] ?? null;
                    if ($next !== null && str_contains($text, $token.' '.$next)) {
                        $score += 2;
                    }
                }

                // A single distinctive service name such as «اینماد» can identify a record.
                if ($score === 1 && count($tokens) === 1 && mb_strlen($tokens[0], 'UTF-8') >= 4) {
                    $score = 2;
                }

                if ($score > $bestScore) {
                    $secondScore = $bestScore;
                    $bestScore = $score;
                    $best = $record;
                } elseif ($score > $secondScore) {
                    $secondScore = $score;
                }            }
        }

        if (! is_array($best) || $bestScore < 2 || ($bestScore - $secondScore) < 1) {
            return null;
        }

        if (($best['service_key'] ?? null) === 'guild-business-license') {
            $activity = $this->classifyGuildActivity($text);
            if (($activity['needs_clarification'] ?? true) === true) {
                return 'برای اینکه مسیر درست جواز کسب رو مشخص کنیم، لطفاً اول نوع شغل دقیق‌تون رو بفرمایید و بگید محل فعالیت در کدوم شهره؟';
            }
        }

        $answer = 'برای «'.($best['title'] ?? 'این خدمت').'»، راهنمای اولیه کارگزار به این صورته:';
        $lowerText = $text;

        if (str_contains($lowerText, 'مدرک') || str_contains($lowerText, 'مدارک')) {
            $items = $this->firstItems($best['documents'] ?? [], 5);
            if ($items !== []) {
                $answer .= "\n\nمدارک قابل بررسی:\n".$this->formatItems($items);
            }
        } elseif (str_contains($lowerText, 'مرحله') || str_contains($lowerText, 'مراحل') || str_contains($lowerText, 'چطور')) {
            $items = $this->firstItems($best['steps'] ?? [], 5);
            if ($items !== []) {
                $answer .= "\n\nمراحل کلی:\n".$this->formatItems($items);
            }
        } elseif (str_contains($lowerText, 'شرط') || str_contains($lowerText, 'شرایط')) {
            $items = $this->firstItems($best['conditions'] ?? [], 5);
            if ($items !== []) {
                $answer .= "\n\nشرایط اولیه:\n".$this->formatItems($items);
            }
        } else {
            $summary = $best['what_is_it'] ?? $best['scope'] ?? $best['eligibility'] ?? null;
            if (is_string($summary) && trim($summary) !== '') {
                $answer .= "\n\n".$summary;
            }
            $items = $this->firstItems($best['conditions'] ?? [], 3);
            if ($items !== []) {
                $answer .= "\n\nمواردی که معمولاً بررسی می‌شن:\n".$this->formatItems($items);
            }
        }

        $verification = (string) ($best['verification_status'] ?? 'needs_review');
        if ($verification !== 'verified_current') {
            $answer .= "\n\nاین راهنمای اولیه‌ست؛ جزئیات نهایی باید با شرایط پرونده و آخرین ضوابط مرجع مربوط بررسی بشه.";
        }

        return $this->appendCustomerClosing($answer);
    }

    private function appendCustomerClosing(string $answer): string
    {
        $closing = (string) config(
            'support_assistant.customer_communication.standard_closing_text',
            config('support_assistant.service_assurance_closing', '')
        );

        if ($closing !== '' && ! str_contains($answer, $closing)) {
            return rtrim($answer)."\n\n".$closing;
        }

        return $answer;
    }

    private function firstItems(mixed $items, int $limit): array
    {
        if (! is_array($items)) {
            return is_string($items) && trim($items) !== '' ? [trim($items)] : [];
        }

        $items = array_values(array_filter($items, fn ($item) => is_string($item) && trim($item) !== ''));
        return array_slice($items, 0, $limit);
    }

    private function formatItems(array $items): string
    {
        $lines = [];
        foreach ($items as $index => $item) {
            $lines[] = ($index + 1).'. '.trim($item);
        }

        return implode("\n", $lines);
    }

    /**
     * Classify a guild activity into one or more specialist requirement groups.
     * The official worksheet for the exact activity remains authoritative.
     *
     * @return array{common_preflight: array, groups: array, requirements: array, needs_clarification: bool, default_only: bool, official_worksheet_overrides_classifier: bool}
     */
    public function classifyGuildActivity(string $activity): array
    {
        $text = $this->normalize($activity);
        $rules = config('support_assistant.guild_job_classification', []);
        $matchedGroups = [];
        $requirements = [];

        foreach (($rules['groups'] ?? []) as $groupKey => $group) {
            $matchedKeywords = [];
            foreach (($group['keywords'] ?? []) as $keyword) {
                $needle = $this->normalize($keyword);
                if ($needle !== '' && str_contains($text, $needle)) {
                    $matchedKeywords[] = $keyword;
                }
            }

            foreach (($group['exclude_if_only'] ?? []) as $excluded) {
                $excludedNeedle = $this->normalize($excluded);
                if ($excludedNeedle !== '' && str_contains($text, $excludedNeedle)) {
                    $matchedKeywords = [];
                    break;
                }
            }

            if ($matchedKeywords === []) {
                continue;
            }

            $matchedGroups[] = [
                'key' => $groupKey,
                'title' => $group['title'] ?? $groupKey,
                'matched_keywords' => $matchedKeywords,
                'requirements' => $group['requirements'] ?? [],
            ];
            foreach (($group['requirements'] ?? []) as $requirement) {
                if (! in_array($requirement, $requirements, true)) {
                    $requirements[] = $requirement;
                }
            }
        }

        return [
            'common_preflight' => $rules['common_preflight'] ?? [],
            'groups' => $matchedGroups,
            'requirements' => $requirements,
            'needs_clarification' => $matchedGroups === [],
            'default_only' => $matchedGroups === [],
            'official_worksheet_overrides_classifier' => (bool) ($rules['official_worksheet_overrides_classifier'] ?? true),
        ];
    }

    private function normalize(string $value): string
    {
        $value = strtr(mb_strtolower($value, 'UTF-8'), [
            'ي' => 'ی',
            'ى' => 'ی',
            'ك' => 'ک',
            'ۀ' => 'ه',
            'ة' => 'ه',
            'أ' => 'ا',
            'إ' => 'ا',
            'ؤ' => 'و',
            'ئ' => 'ی',
            '‌' => ' ',
        ]);

        $value = preg_replace('/[^\p{L}\p{N}\s]/u', ' ', $value) ?? $value;
        return trim(preg_replace('/\s+/u', ' ', $value) ?? $value);
    }
}
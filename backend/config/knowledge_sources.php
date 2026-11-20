<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Shared knowledge-source routing
    |--------------------------------------------------------------------------
    | "local" means reviewed, versioned first-party knowledge.
    | "live" means retrieval from the named official portal at request time.
    | "hybrid" means local guidance plus live verification of volatile facts.
    |
    | A live source must not be marked operational until its real public
    | search/worksheet flow has been inspected and an integration test passes.
    */
    'services' => [
        'guild-business-license' => [
            'mode' => 'live',
            'source' => 'iran_national_license_portal',
            'knowledge_file' => null,
        ],
        'home-business-license' => [
            'mode' => 'live',
            'source' => 'iran_national_license_portal',
            'knowledge_file' => null,
        ],
        'company-registration' => [
            'mode' => 'local',
            'source' => 'company_registration_knowledge',
            'knowledge_file' => 'company_registration_knowledge.json',
        ],
        'trademark-registration' => [
            'mode' => 'hybrid',
            'source' => 'trademark_registration_knowledge',
            'knowledge_file' => 'trademark_registration_knowledge.json',
            'live_verification_source' => 'iran_intellectual_property_portal',
        ],
        'logo-and-industrial-design-registration' => [
            'mode' => 'hybrid',
            'source' => 'trademark_registration_knowledge',
            'knowledge_file' => 'trademark_registration_knowledge.json',
            'live_verification_source' => 'iran_intellectual_property_portal',
        ],
    ],

    'sources' => [
        'iran_national_license_portal' => [
            'name' => 'درگاه ملی مجوزهای کشور',
            'base_url' => 'https://mojavez.ir/',
            'status' => 'adapter_pending_portal_flow_verification',
            'search_url' => null,
            'notes' => 'آدرس جست‌وجو یا API تا زمان مشاهده و آزمون واقعی سامانه تعیین نمی‌شود.',
        ],
        'iran_intellectual_property_portal' => [
            'name' => 'سامانه رسمی مالکیت صنعتی',
            'base_url' => null,
            'status' => 'source_url_and_flow_pending_verification',
            'search_url' => null,
            'notes' => 'دامنه و مسیر جست‌وجوی رسمی باید پیش از اتصال بررسی و تأیید شود.',
        ],
    ],

    'retrieval' => [
        'local_documents_path' => resource_path('knowledge'),
        'require_approved_document' => true,
        'require_review_date' => true,
        'default_live_timeout_seconds' => 8,
        'cache_ttl_seconds' => 3600,
    ],
];

<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Shared knowledge-source routing
    |--------------------------------------------------------------------------
    | local: reviewed, versioned first-party knowledge.
    | live: retrieve current information from an official portal.
    | hybrid: use reviewed local guidance and verify volatile facts live.
    |
    | A live source is not operational until its real public search/worksheet
    | flow has been inspected and an end-to-end integration test passes.
    */
    'services' => [
        'guild-business-license' => [
            'mode' => 'live',
            'source' => 'iran_national_license_portal',
        ],
        'home-business-license' => [
            'mode' => 'live',
            'source' => 'iran_national_license_portal',
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
        'health-permits' => [
            'mode' => 'live',
            'source' => 'official_health_permit_portal',
        ],
        'standards-certification' => [
            'mode' => 'live',
            'source' => 'iran_national_standards_portal',
        ],
        'tax-services' => [
            'mode' => 'hybrid',
            'source' => 'tax_knowledge',
            'knowledge_file' => null,
            'live_verification_source' => 'iran_tax_portal',
        ],
        'enamad' => [
            'mode' => 'hybrid',
            'source' => 'enamad_knowledge',
            'knowledge_file' => null,
            'live_verification_source' => 'enamad_official_portal',
        ],
    ],

    'sources' => [
        'company_registration_knowledge' => [
            'name' => 'بانک دانش داخلی ثبت شرکت',
            'base_url' => null,
            'status' => 'local_document_pending_legal_review',
            'search_url' => null,
        ],
        'trademark_registration_knowledge' => [
            'name' => 'بانک دانش داخلی مالکیت صنعتی',
            'base_url' => null,
            'status' => 'local_document_pending_legal_review',
            'search_url' => null,
        ],
        'iran_national_license_portal' => [
            'name' => 'درگاه ملی مجوزهای کشور',
            'base_url' => 'https://mojavez.ir/',
            'status' => 'adapter_pending_portal_flow_verification',
            'search_url' => null,
            'notes' => 'مسیر جست‌وجو یا API تا زمان مشاهده و آزمون واقعی سامانه تعیین نمی‌شود.',
        ],
        'iran_intellectual_property_portal' => [
            'name' => 'سامانه رسمی مالکیت صنعتی',
            'base_url' => null,
            'status' => 'source_url_and_flow_pending_verification',
            'search_url' => null,
        ],
        'official_health_permit_portal' => [
            'name' => 'مرجع رسمی مجوزهای بهداشتی',
            'base_url' => null,
            'status' => 'source_identification_pending',
            'search_url' => null,
        ],
        'iran_national_standards_portal' => [
            'name' => 'سازمان ملی استاندارد ایران',
            'base_url' => null,
            'status' => 'source_url_and_flow_pending_verification',
            'search_url' => null,
        ],
        'tax_knowledge' => [
            'name' => 'بانک دانش خدمات مالیاتی کارگزار',
            'base_url' => null,
            'status' => 'local_document_not_created',
            'search_url' => null,
        ],
        'iran_tax_portal' => [
            'name' => 'درگاه رسمی خدمات مالیاتی',
            'base_url' => null,
            'status' => 'source_url_and_flow_pending_verification',
            'search_url' => null,
        ],
        'enamad_knowledge' => [
            'name' => 'بانک دانش اینماد کارگزار',
            'base_url' => null,
            'status' => 'local_document_not_created',
            'search_url' => null,
        ],
        'enamad_official_portal' => [
            'name' => 'سامانه رسمی نماد اعتماد الکترونیکی',
            'base_url' => null,
            'status' => 'source_url_and_flow_pending_verification',
            'search_url' => null,
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

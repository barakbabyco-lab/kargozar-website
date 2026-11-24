<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Shared knowledge-source routing for all ten Kargozar categories
    |--------------------------------------------------------------------------
    | local: reviewed, versioned first-party knowledge.
    | live: retrieve current information from an official portal.
    | hybrid: local guidance plus live verification of volatile facts.
    |
    | No live source is operational until its real public flow is verified.
    */
    'services' => [
        // 01. مجوزهای کسب‌وکار
        'guild-business-license' => ['mode' => 'live', 'source' => 'iran_national_license_portal', 'knowledge_file' => 'category_01_business_licenses.json'],
        'home-business-license' => ['mode' => 'live', 'source' => 'iran_national_license_portal', 'knowledge_file' => 'category_01_business_licenses.json'],
        'industrial-establishment-permits' => ['mode' => 'live', 'source' => 'iran_national_license_portal', 'knowledge_file' => 'category_01_business_licenses.json'],

        // 02. ثبت شرکت
        'company-registration' => ['mode' => 'hybrid', 'source' => 'company_registration_knowledge', 'knowledge_file' => 'category_02_company_registration.json', 'live_verification_source' => 'iran_company_registration_portal'],
        'company-changes' => ['mode' => 'hybrid', 'source' => 'company_registration_knowledge', 'knowledge_file' => 'category_02_company_registration.json', 'live_verification_source' => 'iran_company_registration_portal'],
        'company-dissolution' => ['mode' => 'hybrid', 'source' => 'company_registration_knowledge', 'knowledge_file' => 'category_02_company_registration.json', 'live_verification_source' => 'iran_company_registration_portal'],

        // 03. ثبت برند و مالکیت فکری
        'trademark-registration' => ['mode' => 'hybrid', 'source' => 'trademark_registration_knowledge', 'knowledge_file' => 'category_03_intellectual_property.json', 'live_verification_source' => 'iran_intellectual_property_portal'],
        'logo-registration' => ['mode' => 'hybrid', 'source' => 'trademark_registration_knowledge', 'knowledge_file' => 'category_03_intellectual_property.json', 'live_verification_source' => 'iran_intellectual_property_portal'],
        'industrial-design-registration' => ['mode' => 'hybrid', 'source' => 'trademark_registration_knowledge', 'knowledge_file' => 'category_03_intellectual_property.json', 'live_verification_source' => 'iran_intellectual_property_portal'],
        'invention-registration' => ['mode' => 'hybrid', 'source' => 'trademark_registration_knowledge', 'knowledge_file' => 'category_03_intellectual_property.json', 'live_verification_source' => 'iran_intellectual_property_portal'],

        // 04. مدارک و تأییدیه‌های مکمل
        'police-public-places-approval' => ['mode' => 'hybrid', 'source' => 'complementary_approvals_knowledge', 'knowledge_file' => 'category_04_complementary_documents_approvals.json', 'live_verification_source' => 'iran_national_license_portal'],
        'health-card' => ['mode' => 'hybrid', 'source' => 'complementary_approvals_knowledge', 'knowledge_file' => 'category_04_complementary_documents_approvals.json', 'live_verification_source' => 'iran_health_authority'],
        'environment-health-approval' => ['mode' => 'hybrid', 'source' => 'complementary_approvals_knowledge', 'knowledge_file' => 'category_04_complementary_documents_approvals.json', 'live_verification_source' => 'iran_health_authority'],
        'trade-law-training-certificate' => ['mode' => 'hybrid', 'source' => 'complementary_approvals_knowledge', 'knowledge_file' => 'category_04_complementary_documents_approvals.json', 'live_verification_source' => 'iran_national_license_portal'],
        'national-standards-approval' => ['mode' => 'hybrid', 'source' => 'complementary_approvals_knowledge', 'knowledge_file' => 'category_04_complementary_documents_approvals.json', 'live_verification_source' => 'iran_national_standards_portal'],
        'other-regulatory-approvals' => ['mode' => 'hybrid', 'source' => 'complementary_approvals_knowledge', 'knowledge_file' => 'category_04_complementary_documents_approvals.json', 'live_verification_source' => 'relevant_official_authority'],

        // 05. خدمات بانکی
        'business-account-opening' => ['mode' => 'hybrid', 'source' => 'banking_knowledge', 'knowledge_file' => 'category_05_banking_services.json', 'live_verification_source' => 'selected_bank_official_source'],
        'banking-facilities' => ['mode' => 'hybrid', 'source' => 'banking_knowledge', 'knowledge_file' => 'category_05_banking_services.json', 'live_verification_source' => 'selected_bank_official_source'],
        'bank-guarantees' => ['mode' => 'hybrid', 'source' => 'banking_knowledge', 'knowledge_file' => 'category_05_banking_services.json', 'live_verification_source' => 'selected_bank_official_source'],

        // 06. خدمات حقوقی و قراردادی
        'employment-contract' => ['mode' => 'local', 'source' => 'legal_contracts_knowledge', 'knowledge_file' => 'category_06_legal_and_contractual.json'],
        'contractor-agreement' => ['mode' => 'local', 'source' => 'legal_contracts_knowledge', 'knowledge_file' => 'category_06_legal_and_contractual.json'],
        'business-contracts' => ['mode' => 'local', 'source' => 'legal_contracts_knowledge', 'knowledge_file' => 'category_06_legal_and_contractual.json'],
        'legal-documentation' => ['mode' => 'hybrid', 'source' => 'legal_contracts_knowledge', 'knowledge_file' => 'category_06_legal_and_contractual.json', 'live_verification_source' => 'iran_official_laws_portal'],

        // 07. خدمات اینترنتی و تجاری
        'enamad' => ['mode' => 'hybrid', 'source' => 'internet_commercial_knowledge', 'knowledge_file' => 'category_07_internet_and_commercial_services.json', 'live_verification_source' => 'enamad_official_portal'],
        'business-website' => ['mode' => 'local', 'source' => 'internet_commercial_knowledge', 'knowledge_file' => 'category_07_internet_and_commercial_services.json'],
        'payment-gateway' => ['mode' => 'hybrid', 'source' => 'internet_commercial_knowledge', 'knowledge_file' => 'category_07_internet_and_commercial_services.json', 'live_verification_source' => 'payment_provider_official_source'],
        'business-domain' => ['mode' => 'hybrid', 'source' => 'internet_commercial_knowledge', 'knowledge_file' => 'category_07_internet_and_commercial_services.json', 'live_verification_source' => 'domain_registry_official_source'],
        'bulk-sms' => ['mode' => 'hybrid', 'source' => 'internet_commercial_knowledge', 'knowledge_file' => 'category_07_internet_and_commercial_services.json', 'live_verification_source' => 'selected_sms_provider'],
        'internet-phone' => ['mode' => 'hybrid', 'source' => 'internet_commercial_knowledge', 'knowledge_file' => 'category_07_internet_and_commercial_services.json', 'live_verification_source' => 'selected_voip_provider'],

        // 08. خدمات ملکی و قراردادها
        'lease-tracking-code' => ['mode' => 'hybrid', 'source' => 'property_knowledge', 'knowledge_file' => 'category_08_property_and_leases.json', 'live_verification_source' => 'iran_real_estate_transaction_system'],
        'tax-file-and-tracking' => ['mode' => 'hybrid', 'source' => 'complementary_approvals_knowledge', 'knowledge_file' => 'category_04_complementary_documents_approvals.json', 'live_verification_source' => 'iran_tax_portal'],
        'property-contracts' => ['mode' => 'local', 'source' => 'property_knowledge', 'knowledge_file' => 'category_08_property_and_leases.json'],
        'property-document-followup' => ['mode' => 'hybrid', 'source' => 'property_knowledge', 'knowledge_file' => 'category_08_property_and_leases.json', 'live_verification_source' => 'relevant_official_property_authority'],

        // 09. خدمات توسعه کسب‌وکار
        'accounting-software' => ['mode' => 'local', 'source' => 'business_development_knowledge', 'knowledge_file' => 'category_09_business_development.json'],
        'sales-invoicing' => ['mode' => 'local', 'source' => 'business_development_knowledge', 'knowledge_file' => 'category_09_business_development.json'],
        'payroll-hr' => ['mode' => 'local', 'source' => 'business_development_knowledge', 'knowledge_file' => 'category_09_business_development.json'],
        'human-resources' => ['mode' => 'local', 'source' => 'business_development_knowledge', 'knowledge_file' => 'category_09_business_development.json'],
        'contract-management' => ['mode' => 'local', 'source' => 'business_development_knowledge', 'knowledge_file' => 'category_09_business_development.json'],
        'crm' => ['mode' => 'local', 'source' => 'business_development_knowledge', 'knowledge_file' => 'category_09_business_development.json'],
        'inventory-management' => ['mode' => 'local', 'source' => 'business_development_knowledge', 'knowledge_file' => 'category_09_business_development.json'],

        // 10. سایر خدمات تخصصی
        'business-consulting' => ['mode' => 'local', 'source' => 'specialized_services_knowledge', 'knowledge_file' => 'category_10_specialized_services.json'],
        'feasibility-study' => ['mode' => 'local', 'source' => 'specialized_services_knowledge', 'knowledge_file' => 'category_10_specialized_services.json'],
        'business-plan' => ['mode' => 'local', 'source' => 'specialized_services_knowledge', 'knowledge_file' => 'category_10_specialized_services.json'],
        'business-valuation' => ['mode' => 'local', 'source' => 'specialized_services_knowledge', 'knowledge_file' => 'category_10_specialized_services.json'],
        'fundraising' => ['mode' => 'hybrid', 'source' => 'specialized_services_knowledge', 'knowledge_file' => 'category_10_specialized_services.json', 'live_verification_source' => 'selected_investment_or_funding_authority'],
        'advertising-video' => ['mode' => 'local', 'source' => 'specialized_services_knowledge', 'knowledge_file' => 'category_10_specialized_services.json'],
        'business-branding' => ['mode' => 'local', 'source' => 'specialized_services_knowledge', 'knowledge_file' => 'category_10_specialized_services.json'],
    ],

    'sources' => [
        'company_registration_knowledge' => ['name' => 'بانک دانش ثبت شرکت', 'base_url' => null, 'status' => 'local_document_pending_legal_review', 'search_url' => null],
        'trademark_registration_knowledge' => ['name' => 'بانک دانش مالکیت فکری', 'base_url' => null, 'status' => 'local_document_pending_legal_review', 'search_url' => null],
        'complementary_approvals_knowledge' => ['name' => 'بانک دانش مدارک و تأییدیه‌های مکمل', 'base_url' => null, 'status' => 'local_document_pending_authority_review', 'search_url' => null],
        'banking_knowledge' => ['name' => 'بانک دانش خدمات بانکی', 'base_url' => null, 'status' => 'local_document_pending_review', 'search_url' => null],
        'legal_contracts_knowledge' => ['name' => 'بانک دانش حقوقی و قراردادی', 'base_url' => null, 'status' => 'local_document_pending_legal_review', 'search_url' => null],
        'internet_commercial_knowledge' => ['name' => 'بانک دانش خدمات اینترنتی و تجاری', 'base_url' => null, 'status' => 'local_document_pending_review', 'search_url' => null],
        'property_knowledge' => ['name' => 'بانک دانش خدمات ملکی', 'base_url' => null, 'status' => 'local_document_pending_legal_review', 'search_url' => null],
        'business_development_knowledge' => ['name' => 'بانک دانش توسعه کسب‌وکار', 'base_url' => null, 'status' => 'local_document_pending_review', 'search_url' => null],
        'specialized_services_knowledge' => ['name' => 'بانک دانش خدمات تخصصی', 'base_url' => null, 'status' => 'local_document_pending_review', 'search_url' => null],
        'iran_national_license_portal' => ['name' => 'درگاه ملی مجوزهای کشور', 'base_url' => 'https://mojavez.ir/', 'status' => 'adapter_pending_portal_flow_verification', 'search_url' => null],
        'iran_intellectual_property_portal' => ['name' => 'سامانه رسمی مالکیت صنعتی', 'base_url' => 'https://iripo.ssaa.ir/', 'status' => 'official_domain_identified_exact_workflow_pending_verification', 'search_url' => 'https://ipm.ssaa.ir/'],
        'iran_company_registration_portal' => ['name' => 'سامانه رسمی ثبت شرکت‌ها', 'base_url' => 'https://irsherkat.ssaa.ir/', 'status' => 'official_domain_identified_exact_workflow_pending_verification', 'search_url' => null],
        'iran_health_authority' => ['name' => 'مراجع رسمی وزارت بهداشت و دانشگاه‌های علوم پزشکی', 'base_url' => 'https://behdasht.gov.ir/', 'status' => 'ministry_domain_identified_local_health_authority_workflow_pending_verification', 'search_url' => null],
        'iran_national_standards_portal' => ['name' => 'سازمان ملی استاندارد ایران', 'base_url' => 'https://inso.gov.ir/', 'status' => 'official_domain_identified_exact_workflow_pending_verification', 'search_url' => null],
        'iran_tax_portal' => ['name' => 'درگاه رسمی خدمات مالیاتی', 'base_url' => 'https://my.tax.gov.ir/', 'status' => 'official_domain_identified_exact_workflow_pending_verification', 'search_url' => null],
        'enamad_official_portal' => ['name' => 'سامانه رسمی نماد اعتماد الکترونیکی', 'base_url' => 'https://enamad.ir/', 'status' => 'official_domain_identified_exact_workflow_pending_verification', 'search_url' => null],
        'selected_bank_official_source' => ['name' => 'سامانه و دستورالعمل رسمی بانک انتخابی', 'base_url' => null, 'status' => 'provider_selected_per_request', 'search_url' => null],
        'iran_official_laws_portal' => ['name' => 'سامانه رسمی انتشار قوانین و مقررات', 'base_url' => null, 'status' => 'source_url_pending_verification', 'search_url' => null],
        'payment_provider_official_source' => ['name' => 'درگاه رسمی ارائه‌دهنده پرداخت انتخابی', 'base_url' => null, 'status' => 'provider_selected_per_request', 'search_url' => null],
        'domain_registry_official_source' => ['name' => 'مرجع رسمی ثبت دامنه', 'base_url' => null, 'status' => 'source_url_pending_verification', 'search_url' => null],
        'selected_sms_provider' => ['name' => 'ارائه‌دهنده پنل پیامک انتخابی', 'base_url' => null, 'status' => 'provider_selected_per_request', 'search_url' => null],
        'selected_voip_provider' => ['name' => 'ارائه‌دهنده تلفن اینترنتی انتخابی', 'base_url' => null, 'status' => 'provider_selected_per_request', 'search_url' => null],
        'iran_real_estate_transaction_system' => ['name' => 'سامانه رسمی معاملات املاک و مستغلات', 'base_url' => null, 'status' => 'source_url_and_flow_pending_verification', 'search_url' => null],
        'relevant_official_authority' => ['name' => 'مرجع رسمی ذی‌ربط بر اساس موضوع خدمت', 'base_url' => null, 'status' => 'authority_selected_per_request', 'search_url' => null],
        'selected_investment_or_funding_authority' => ['name' => 'مرجع تأمین مالی یا سرمایه‌گذاری انتخابی', 'base_url' => null, 'status' => 'authority_selected_per_request', 'search_url' => null],
    ],

    'retrieval' => [
        'local_documents_path' => resource_path('knowledge'),
        'shared_knowledge_file' => 'shared_requirement_library.json',
        'require_approved_document' => true,
        'require_review_date' => true,
        'default_live_timeout_seconds' => 8,
        'cache_ttl_seconds' => 3600,
    ],
];

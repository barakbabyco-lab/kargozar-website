import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const kargozarAssetsBaseUrl = String.fromEnvironment(
  'KARGOZAR_ASSETS_BASE_URL',
  defaultValue: '',
);

const serviceCategoryImages = <String, String>{
  'business-licenses': 'service-01-business-permits.webp',
  'trademark-intellectual-property': 'service-02-brand-registration.webp',
  'company-registration': 'service-03-company-registration.webp',
  'supplementary-certificates': 'service-04-certifications.webp',
  'banking-services': 'service-05-banking.webp',
  'legal-contract-services': 'service-06-legal-services.webp',
  'internet-commerce-services': 'service-07-digital-services.webp',
  'real-estate-contracts': 'service-08-real-estate.webp',
  'business-development': 'service-09-business-development.webp',
  'specialized-services': 'service-10-specialized-services.webp',
};

class CompanionSubmodule {
  const CompanionSubmodule({
    required this.title,
    required this.description,
    required this.icon,
    this.points = const [],
  });

  final String title;
  final String description;
  final IconData icon;
  final List<String> points;
}

class CompanionModule {
  const CompanionModule(
    this.title,
    this.subtitle,
    this.image,
    this.icon, {
    this.description,
    this.points = const [],
    this.children = const [],
  });

  final String title;
  final String subtitle;
  final String image;
  final IconData icon;
  final String? description;
  final List<String> points;
  final List<CompanionSubmodule> children;
}

const companionModules = <CompanionModule>[
  CompanionModule(
    'پکیج‌های کارگزار',
    'راهکارهای آماده و مقرون‌به‌صرفه برای شروع و توسعه کسب‌وکار',
    'companion-01-packages.webp',
    Icons.inventory_2_outlined,
    description: 'پکیج‌های کارگزار مجموعه‌ای از خدمات موردنیاز برای راه‌اندازی یا سامان‌دهی کسب‌وکار را در قالبی یکپارچه ارائه می‌کنند. ترکیب خدمات هر پکیج بر اساس نیاز متقاضی و دامنه خدمات قابل ارائه مشخص می‌شود.',
    points: [
      'امکان انتخاب یک مجوز شغلی متناسب با فعالیت متقاضی در پکیج پایه',
      'اقلام اداری شامل سربرگ، پاکت، کارت ویزیت و مهر اختصاصی',
      'نرم‌افزار حسابداری و صدور فاکتور',
      'نرم‌افزار حقوق و دستمزد و تهیه فیش حقوقی',
      'نمونه قرارداد استخدام و پیمانکاری',
      'در پکیج ویژه پلاس، خدمات تکمیلی معرفی و توسعه کسب‌وکار نیز در نظر گرفته شده است؛ ترکیب نهایی اقلام آن پیش از سفارش اعلام می‌شود',
    ],
    children: [
      CompanionSubmodule(
        title: 'پکیج پایه',
        description: 'بسته‌ای برای شروع فعالیت و فراهم‌کردن ابزارهای اداری و مدیریتی اولیه کسب‌وکار.',
        icon: Icons.inventory_2_outlined,
        points: [
          'یک مجوز شغلی به انتخاب متقاضی، پس از بررسی امکان‌پذیری',
          'ست اداری شامل سربرگ، پاکت و کارت ویزیت',
          'مهر اختصاصی',
          'نرم‌افزار حسابداری و صدور فاکتور',
          'نرم‌افزار حقوق و دستمزد و فیش حقوقی',
          'نمونه قرارداد استخدام و پیمانکاری',
        ],
      ),
      CompanionSubmodule(
        title: 'پکیج ویژه',
        description: 'پکیج پایه به‌همراه ابزارهای تکمیلی برای حضور حرفه‌ای‌تر و توسعه ارتباط با مشتریان.',
        icon: Icons.workspace_premium_outlined,
        points: [
          'تمام خدمات و اقلام پکیج پایه',
          'وب‌سایت با دامنه اختصاصی',
          'تیزر معرفی کسب‌وکار',
          'پوستر و بنر تبلیغاتی',
          'تلفن اینترنتی',
          'پنل پیامک انبوه',
        ],
      ),
      CompanionSubmodule(
        title: 'پکیج ویژه پلاس',
        description: 'سطح تکمیلی پکیج‌های کارگزار برای نیازهای گسترده‌تر کسب‌وکار. جزئیات اقلام و ترکیب نهایی این سطح پیش از ثبت سفارش به‌صورت شفاف اعلام می‌شود.',
        icon: Icons.stars_outlined,
        points: [
          'بررسی نیازهای تکمیلی کسب‌وکار',
          'تعیین خدمات و امکانات قابل ارائه متناسب با درخواست',
          'اعلام ترکیب و شرایط نهایی پیش از سفارش',
        ],
      ),
    ],
  ),
  CompanionModule(
    'استودیو طراحی',
    'طراحی هویت بصری، محصولات و محتوای تخصصی',
    'companion-02-design-studio.webp',
    Icons.design_services_outlined,
    description: 'استودیو طراحی کارگزار برای طراحی و آماده‌سازی اقلام بصری و تبلیغاتی کسب‌وکار فعالیت می‌کند؛ از شکل‌گیری هویت برند تا تولید فایل‌های موردنیاز برای چاپ و انتشار دیجیتال.',
    points: [
      'طراحی متناسب با حوزه فعالیت و مخاطبان برند',
      'هماهنگی اجزای بصری در اقلام مختلف',
      'تحویل خروجی متناسب با کاربرد چاپی یا دیجیتال',
    ],
    children: [
      CompanionSubmodule(title: 'لوگو و هویت بصری', description: 'طراحی یا بازطراحی نشان تجاری و عناصر اصلی هویت بصری برند.', icon: Icons.branding_watermark_outlined, points: ['طراحی لوگو و نشانه', 'انتخاب رنگ و تایپوگرافی برند', 'تدوین کاربردهای پایه هویت بصری']),
      CompanionSubmodule(title: 'کارت ویزیت و ست اداری', description: 'طراحی اقلام اداری هماهنگ با هویت بصری کسب‌وکار.', icon: Icons.badge_outlined, points: ['کارت ویزیت', 'سربرگ و پاکت نامه', 'فرم‌ها و اقلام اداری']),
      CompanionSubmodule(title: 'کاتالوگ و بروشور', description: 'طراحی محتوای معرفی محصولات، خدمات و توانمندی‌های کسب‌وکار.', icon: Icons.menu_book_outlined, points: ['ساختاردهی محتوای معرفی', 'طراحی صفحات و چیدمان', 'آماده‌سازی فایل چاپ و نسخه دیجیتال']),
      CompanionSubmodule(title: 'پوستر و بنر', description: 'طراحی اقلام تبلیغاتی برای محیط چاپی، وب‌سایت و شبکه‌های اجتماعی.', icon: Icons.image_outlined, points: ['پوستر و تراکت', 'بنرهای تبلیغاتی و مناسبتی', 'نسخه‌های متناسب با ابعاد رسانه‌های دیجیتال']),
      CompanionSubmodule(title: 'بسته‌بندی و اقلام تبلیغاتی', description: 'طراحی بسته‌بندی محصول و اقلام مکمل معرفی برند.', icon: Icons.redeem_outlined, points: ['طرح بسته‌بندی و لیبل', 'اقلام تبلیغاتی اختصاصی', 'آماده‌سازی فایل‌های اجرایی']),
    ],
  ),
  CompanionModule(
    'حسابداری و مالی',
    'مدیریت امور مالی و گزارش‌های کسب‌وکار',
    'companion-03-accounting.webp',
    Icons.calculate_outlined,
    description: 'ابزارهای حسابداری و مالی برای ثبت رویدادهای مالی، کنترل دریافت و پرداخت و تهیه گزارش‌های مدیریتی کسب‌وکار.',
    points: ['ثبت درآمدها و هزینه‌ها', 'مدیریت دریافت‌ها و پرداخت‌ها', 'گزارش‌های مالی و مانده حساب‌ها'],
    children: [
      CompanionSubmodule(title: 'نرم‌افزار حسابداری', description: 'ثبت و طبقه‌بندی عملیات مالی روزمره کسب‌وکار.', icon: Icons.calculate_outlined, points: ['ثبت اسناد و سرفصل‌ها', 'گزارش گردش حساب', 'گزارش درآمد و هزینه']),
      CompanionSubmodule(title: 'دریافت و پرداخت', description: 'کنترل وجوه دریافتی، پرداختی و مانده حساب‌ها.', icon: Icons.account_balance_wallet_outlined, points: ['ثبت دریافت و پرداخت', 'پیگیری مطالبات و بدهی‌ها', 'گزارش مانده صندوق و بانک']),
      CompanionSubmodule(title: 'گزارش‌های مالی', description: 'تهیه گزارش‌های خلاصه برای بررسی وضعیت مالی و تصمیم‌گیری.', icon: Icons.analytics_outlined, points: ['گزارش فروش و هزینه', 'گزارش سود و زیان در حدود اطلاعات ثبت‌شده', 'خروجی و گزارش مدیریتی']),
    ],
  ),
  CompanionModule(
    'فاکتور و مدیریت فروش',
    'صدور فاکتور و کنترل فرایند فروش',
    'companion-04-sales-management.webp',
    Icons.point_of_sale_outlined,
    description: 'سامان‌دهی فرایند فروش از ثبت سفارش و صدور پیش‌فاکتور تا صدور فاکتور و پیگیری وضعیت فروش.',
    points: ['صدور پیش‌فاکتور و فاکتور', 'ثبت سفارش مشتریان', 'گزارش فروش و پیگیری وضعیت سفارش‌ها'],
    children: [
      CompanionSubmodule(title: 'صدور فاکتور و پیش‌فاکتور', description: 'تهیه اسناد فروش متناسب با کالا یا خدمات ارائه‌شده.', icon: Icons.receipt_long_outlined, points: ['ثبت اقلام و مبالغ', 'اعمال تخفیف و هزینه‌های مجاز', 'چاپ یا ارسال فاکتور']),
      CompanionSubmodule(title: 'مدیریت سفارش‌ها', description: 'ثبت سفارش و پیگیری مراحل آماده‌سازی و تحویل.', icon: Icons.shopping_cart_outlined, points: ['ثبت سفارش جدید', 'تغییر وضعیت سفارش', 'سوابق سفارش مشتری']),
      CompanionSubmodule(title: 'گزارش فروش', description: 'مشاهده عملکرد فروش بر اساس بازه زمانی و اقلام فروش.', icon: Icons.trending_up_outlined, points: ['گزارش فروش روزانه و دوره‌ای', 'بررسی اقلام پرفروش', 'گزارش مشتریان و سفارش‌ها']),
    ],
  ),
  CompanionModule(
    'پرسنل و منابع انسانی',
    'مدیریت کارکنان، حضور و غیاب و حقوق',
    'companion-05-human-resources.webp',
    Icons.groups_outlined,
    description: 'ابزارهای سامان‌دهی اطلاعات کارکنان و فرایندهای منابع انسانی، از تشکیل پرونده تا محاسبه حقوق و ثبت سوابق.',
    points: ['پرونده و اطلاعات کارکنان', 'حضور و غیاب و مرخصی', 'حقوق، مزایا و فیش حقوقی'],
    children: [
      CompanionSubmodule(title: 'پرونده کارکنان', description: 'ثبت و نگهداری اطلاعات پایه و سوابق پرسنلی.', icon: Icons.folder_shared_outlined, points: ['اطلاعات هویتی و شغلی', 'سوابق همکاری', 'مدارک و مستندات پرسنلی']),
      CompanionSubmodule(title: 'حضور و غیاب و مرخصی', description: 'ثبت کارکرد و مدیریت درخواست‌های مرخصی کارکنان.', icon: Icons.schedule_outlined, points: ['ثبت ورود و خروج', 'ثبت مرخصی و مأموریت', 'گزارش کارکرد']),
      CompanionSubmodule(title: 'حقوق و دستمزد', description: 'محاسبه و سامان‌دهی اطلاعات حقوق و مزایای کارکنان بر اساس اطلاعات و ضوابط مربوط.', icon: Icons.payments_outlined, points: ['اطلاعات حقوق و مزایا', 'محاسبه کارکرد و کسورات', 'تهیه فیش حقوقی']),
    ],
  ),
  CompanionModule(
    'قراردادها و اسناد',
    'سامان‌دهی قراردادها و اسناد کسب‌وکار',
    'companion-06-contracts.webp',
    Icons.description_outlined,
    description: 'خدمات و ابزارهای تهیه، نگهداری و مدیریت اسناد و قراردادهای موردنیاز کسب‌وکار.',
    points: ['تنظیم پیش‌نویس قرارداد متناسب با موضوع', 'مدیریت نسخه‌ها و سوابق', 'یادآوری تعهدات و سررسیدها در صورت فعال بودن ابزار مربوط'],
    children: [
      CompanionSubmodule(title: 'قراردادهای استخدام', description: 'تهیه و سامان‌دهی قراردادهای همکاری با کارکنان.', icon: Icons.badge_outlined, points: ['مشخصات طرفین و موضوع همکاری', 'شرایط و مدت قرارداد', 'تعهدات و پیوست‌ها']),
      CompanionSubmodule(title: 'قراردادهای پیمانکاری', description: 'تنظیم چارچوب همکاری برای اجرای پروژه یا ارائه خدمات.', icon: Icons.handshake_outlined, points: ['شرح کار و محدوده تعهدات', 'مبلغ، پرداخت و زمان‌بندی', 'تحویل، تأیید و ضمانت اجرا']),
      CompanionSubmodule(title: 'قراردادهای تجاری و مشارکت', description: 'سامان‌دهی توافق‌های تجاری و همکاری میان اشخاص یا کسب‌وکارها.', icon: Icons.business_outlined, points: ['موضوع و سهم طرفین', 'تعهدات و تقسیم مسئولیت', 'شرایط خاتمه و حل اختلاف']),
      CompanionSubmodule(title: 'بایگانی اسناد', description: 'نگهداری ساختاریافته قراردادها و اسناد مرتبط با کسب‌وکار.', icon: Icons.archive_outlined, points: ['دسته‌بندی اسناد', 'ثبت تاریخ و طرفین', 'دسترسی به سوابق']),
    ],
  ),
  CompanionModule(
    'تبلیغات و بازاریابی',
    'ابزارهای معرفی و توسعه بازار',
    'companion-07-marketing.webp',
    Icons.campaign_outlined,
    description: 'خدمات تولید محتوای تبلیغاتی و ابزارهای ارتباطی برای معرفی برند، محصولات و خدمات و توسعه بازار.',
    points: ['تولید محتوای تصویری و ویدیویی', 'طراحی اقلام تبلیغاتی', 'ابزارهای ارتباط مستقیم با مخاطبان'],
    children: [
      CompanionSubmodule(title: 'تیزر و ویدئوی تبلیغاتی', description: 'تولید و تدوین ویدئو برای معرفی برند، محصول یا خدمت.', icon: Icons.movie_creation_outlined, points: ['سناریو و ساختار پیام', 'تولید یا تدوین ویدئو', 'نسخه‌های متناسب با رسانه انتشار']),
      CompanionSubmodule(title: 'پوستر و بنر تبلیغاتی', description: 'طراحی محتوای گرافیکی برای کمپین‌ها و معرفی محصولات.', icon: Icons.campaign_outlined, points: ['پوستر و بنر', 'طرح‌های مناسبتی', 'نسخه شبکه‌های اجتماعی']),
      CompanionSubmodule(title: 'پیامک و ارتباط با مشتری', description: 'استفاده از پنل پیامکی برای اطلاع‌رسانی و ارتباطات مجاز با مخاطبان.', icon: Icons.sms_outlined, points: ['ارسال پیامک اطلاع‌رسانی', 'مدیریت فهرست مخاطبان', 'گزارش وضعیت ارسال']),
      CompanionSubmodule(title: 'محتوای معرفی و بازاریابی', description: 'آماده‌سازی متن و محتوای معرفی محصولات و خدمات.', icon: Icons.article_outlined, points: ['متن معرفی کسب‌وکار', 'محتوای معرفی محصول', 'تقویم و ایده‌های محتوایی']),
    ],
  ),
  CompanionModule(
    'انبار و مدیریت موجودی',
    'کنترل کالا، موجودی و گردش انبار',
    'companion-08-inventory.webp',
    Icons.warehouse_outlined,
    description: 'ثبت و کنترل موجودی کالا و مواد، گردش ورود و خروج و سوابق انبار برای کاهش خطا و بهبود تصمیم‌گیری.',
    points: ['تعریف کالا و کدگذاری', 'ثبت ورود و خروج', 'گزارش موجودی و گردش کالا'],
    children: [
      CompanionSubmodule(title: 'تعریف کالا و خدمات', description: 'ثبت مشخصات اقلام و دسته‌بندی آن‌ها برای مدیریت موجودی.', icon: Icons.category_outlined, points: ['نام و کد کالا', 'واحد و گروه‌بندی', 'مشخصات و تنوع کالا']),
      CompanionSubmodule(title: 'ورود و خروج انبار', description: 'ثبت رسیدها و حواله‌های انبار و کنترل گردش اقلام.', icon: Icons.swap_horiz_outlined, points: ['رسید ورود کالا', 'حواله خروج کالا', 'انتقال بین انبارها در صورت پشتیبانی']),
      CompanionSubmodule(title: 'گزارش موجودی', description: 'بررسی موجودی فعلی و سوابق گردش کالا.', icon: Icons.inventory_outlined, points: ['موجودی لحظه‌ای بر اساس داده ثبت‌شده', 'گزارش گردش کالا', 'هشدار حداقل موجودی در صورت فعال بودن']),
    ],
  ),
  CompanionModule(
    'خدمات و امکانات تکمیلی',
    'امکانات کاربردی برای مدیریت بهتر کسب‌وکار',
    'companion-09-extra-services.webp',
    Icons.extension_outlined,
    description: 'خدمات مکملی که در کنار ابزارهای اصلی می‌توانند ارتباطات، حضور آنلاین و عملیات روزمره کسب‌وکار را تقویت کنند.',
    points: ['تلفن و ارتباطات اینترنتی', 'دامنه، وب‌سایت و خدمات آنلاین', 'خدمات پیامکی و امکانات مکمل'],
    children: [
      CompanionSubmodule(title: 'تلفن و ارتباطات اینترنتی', description: 'راه‌اندازی یا تهیه راهکارهای ارتباط تلفنی اینترنتی متناسب با کسب‌وکار.', icon: Icons.phone_in_talk_outlined, points: ['خط تلفن اینترنتی', 'امکانات پاسخ‌گویی و انتقال تماس بر اساس سرویس انتخابی']),
      CompanionSubmodule(title: 'دامنه و وب‌سایت', description: 'خدمات مرتبط با حضور آنلاین کسب‌وکار و راه‌اندازی وب‌سایت.', icon: Icons.language_outlined, points: ['ثبت یا تمدید دامنه', 'میزبانی وب', 'طراحی و راه‌اندازی وب‌سایت']),
      CompanionSubmodule(title: 'پنل پیامک', description: 'تهیه و راه‌اندازی ابزار ارسال پیامک برای اطلاع‌رسانی و ارتباط با مشتریان.', icon: Icons.sms_outlined, points: ['ارسال پیامک خدماتی و اطلاع‌رسانی مجاز', 'مدیریت مخاطبان', 'گزارش ارسال']),
      CompanionSubmodule(title: 'سایر امکانات تکمیلی', description: 'بررسی درخواست‌های مکمل متناسب با نیاز عملیاتی کسب‌وکار.', icon: Icons.extension_outlined, points: ['بررسی نیاز و امکان ارائه', 'اعلام شرایط و دامنه خدمات پیش از سفارش']),
    ],
  ),
];
class AppContentImage extends StatelessWidget {
  const AppContentImage({
    super.key,
    required this.fileName,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_outlined,
    this.borderRadius = 14,
  });

  final String fileName;
  final double? height;
  final double? width;
  final BoxFit fit;
  final IconData fallbackIcon;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final base = kargozarAssetsBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final url = base.isEmpty ? null : Uri.tryParse('$base/$fileName');
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: width,
        child: Image.asset(
          'assets/kargozar/$fileName',
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            if (url != null && url.hasScheme && url.host.isNotEmpty) {
              return Image.network(
                url.toString(),
                fit: fit,
                errorBuilder: (_, __, ___) => _fallback(),
              );
            }
            return _fallback();
          },
        ),
      ),
    );
  }

  Widget _fallback() => Container(
        color: const Color(0xFFF3F0F4),
        alignment: Alignment.center,
        child: Icon(fallbackIcon, color: const Color(0xFF49334F), size: 34),
      );
}

class AppBannerStrip extends StatefulWidget {
  const AppBannerStrip({
    super.key,
    required this.onNavigate,
    required this.onConsultation,
  });

  final ValueChanged<int> onNavigate;
  final VoidCallback onConsultation;

  static const banners = <(String, String, int)>[
    ('banner-01-support.webp', 'تماس و پشتیبانی', 3),
    ('banner-02-business-solutions.webp', 'راهکارهای کسب‌وکار', 2),
    ('banner-03-packages.webp', 'پکیج‌های کارگزار', 4),
    ('banner-04-free-consultation.webp', 'مشاوره رایگان', -1),
    ('banner-05-services.webp', 'مشاهده خدمات', 1),
  ];

  @override
  State<AppBannerStrip> createState() => _AppBannerStripState();
}

class _AppBannerStripState extends State<AppBannerStrip> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % AppBannerStrip.banners.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 142,
        width: double.infinity,
        child: PageView.builder(
          controller: _pageController,
          itemCount: AppBannerStrip.banners.length,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemBuilder: (context, index) {
            final item = AppBannerStrip.banners[index];
            return SizedBox(
              width: MediaQuery.sizeOf(context).width,
              child: Material(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: item.$3 == -1
                      ? widget.onConsultation
                      : () => widget.onNavigate(item.$3),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppContentImage(fileName: item.$1, borderRadius: 0),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xE649334F),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.$2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class CompanionContentPage extends StatelessWidget {
  const CompanionContentPage({
    super.key,
    required this.onOpenDetails,
    required this.onExpand,
    required this.onNavigate,
    required this.onConsultation,
  });

  final ValueChanged<CompanionModule> onOpenDetails;
  final ValueChanged<CompanionModule> onExpand;
  final ValueChanged<int> onNavigate;
  final VoidCallback onConsultation;

  @override
  Widget build(BuildContext context) => ListView(
        padding: EdgeInsets.zero,
        children: [
          AppBannerStrip(
            onNavigate: onNavigate,
            onConsultation: onConsultation,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                for (var i = 0; i < companionModules.length; i++) ...[
                  CompanionModuleRow(
                    title: companionModules[i].title,
                    subtitle: companionModules[i].subtitle,
                    icon: companionModules[i].icon,
                    hasChildren: companionModules[i].children.isNotEmpty,
                    onDetails: () => onOpenDetails(companionModules[i]),
                    onExpand: companionModules[i].children.isEmpty
                        ? null
                        : () => onExpand(companionModules[i]),
                  ),
                  if (i != companionModules.length - 1)
                    const SizedBox(height: 7),
                ],
              ],
            ),
          ),
        ],
      );
}

class CompanionModuleRow extends StatelessWidget {
  const CompanionModuleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.hasChildren,
    required this.onDetails,
    this.onExpand,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool hasChildren;
  final VoidCallback onDetails;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF0B9B9)),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onDetails,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    child: Row(
                      children: [
                        Icon(icon, color: const Color(0xFFC62828), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              )),
                              Text(subtitle, style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 10,
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (hasChildren)
                IconButton(
                  tooltip: 'نمایش زیرشاخه‌ها',
                  onPressed: onExpand,
                  icon: const Icon(Icons.chevron_left_rounded,
                    color: Color(0xFF64748B), size: 21),
                )
              else
                const SizedBox(width: 12),
            ],
          ),
        ),
      );
}

class CompanionDescriptionPage extends StatelessWidget {
  const CompanionDescriptionPage({
    super.key,
    required this.title,
    required this.description,
    required this.image,
    required this.icon,
    required this.points,
  });

  final String title;
  final String description;
  final String image;
  final IconData icon;
  final List<String> points;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('معرفی بخش')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            AppContentImage(
              fileName: image,
              height: 170,
              width: double.infinity,
              fallbackIcon: icon,
            ),
            const SizedBox(height: 18),
            Text(title, style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            )),
            const SizedBox(height: 10),
            Text(description, style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              height: 1.9,
            )),
            if (points.isNotEmpty) ...[
              const SizedBox(height: 22),
              const Text('شرح خدمات و امکانات', style: TextStyle(
                color: Color(0xFF49334F),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              )),
              const SizedBox(height: 10),
              for (final point in points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline,
                        color: Color(0xFFC62828), size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(point, style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12,
                        height: 1.8,
                      ))),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F3F8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8DDE9)),
              ),
              child: const Text(
                'برای دریافت جزئیات متناسب با نوع کسب‌وکار، شرایط ارائه و ترکیب نهایی خدمات، می‌توانید با کارشناسان کارگزار مشاوره کنید.',
                style: TextStyle(color: Color(0xFF49334F), fontSize: 12, height: 1.8),
              ),
            ),
          ],
        ),
      );
}

class SupportContentPage extends StatelessWidget {
 const SupportContentPage({super.key,required this.onConsultation,required this.onNavigate});
 final VoidCallback onConsultation; final ValueChanged<int> onNavigate;
 Future<void> _launch(Uri uri,BuildContext context) async {
   final ok=await launchUrl(uri,mode:LaunchMode.externalApplication);
   if(!ok&&context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('امکان باز کردن برنامه موردنظر وجود ندارد.')));
 }
 @override Widget build(BuildContext context)=>ListView(padding:EdgeInsets.zero,children:[
   AppBannerStrip(onNavigate:onNavigate,onConsultation:onConsultation),
   const SizedBox(height:12),
   Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Column(children:[
     _SupportAction(icon:Icons.phone_in_talk_outlined,title:'تماس تلفنی',subtitle:'تماس مستقیم با کارشناسان کارگزار',onTap:()=>_launch(Uri(scheme:'tel',path:'09360952800'),context)),
     const SizedBox(height:7),
     _SupportAction(icon:Icons.email_outlined,title:'ارتباط از طریق ایمیل',subtitle:'ارسال پیام به info@kargozarr.ir',onTap:()=>_launch(Uri(scheme:'mailto',path:'info@kargozarr.ir',queryParameters:{'subject':'ارتباط با پشتیبانی کارگزار'}),context)),
     const SizedBox(height:7),
     const _SupportAction(icon:Icons.confirmation_number_outlined,title:'ثبت و پیگیری تیکت',subtitle:'به‌زودی فعال می‌شود'),
     const SizedBox(height:7),
     const _SupportAction(icon:Icons.smart_toy_outlined,title:'دستیار هوشمند کارگزار',subtitle:'به‌زودی فعال می‌شود'),
   ])),
 ]);
}
class _SupportAction extends StatelessWidget {
 const _SupportAction({required this.icon,required this.title,required this.subtitle,this.onTap});
 final IconData icon; final String title; final String subtitle; final VoidCallback? onTap;
 @override Widget build(BuildContext context)=>Material(color:Colors.white,borderRadius:BorderRadius.circular(12),
   child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(12),child:Container(height:58,padding:const EdgeInsets.symmetric(horizontal:13),
     decoration:BoxDecoration(borderRadius:BorderRadius.circular(12),border:Border.all(color:const Color(0xFFF0B9B9))),
     child:Row(children:[Icon(icon,color:const Color(0xFFC62828),size:22),const SizedBox(width:12),
       Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[
         Text(title,style:const TextStyle(color:Color(0xFF1E293B),fontSize:12,fontWeight:FontWeight.w800)),
         Text(subtitle,style:const TextStyle(color:Color(0xFF64748B),fontSize:10)),
       ])),const Icon(Icons.chevron_left_rounded,color:Color(0xFF64748B),size:20)]),
   )),
 );
}

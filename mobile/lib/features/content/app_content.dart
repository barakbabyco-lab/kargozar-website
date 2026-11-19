import 'package:flutter/material.dart';

const kargozarAssetsBaseUrl = String.fromEnvironment(
  'KARGOZAR_ASSETS_BASE_URL',
  defaultValue: '',
);

const serviceCategoryImages = <String, String>{
  'business-licenses': 'service-01-business-permits.png',
  'trademark-intellectual-property': 'service-02-brand-registration.png',
  'company-registration': 'service-03-company-registration.png',
  'supplementary-certificates': 'service-04-certifications.png',
  'banking-services': 'service-05-banking.png',
  'legal-contract-services': 'service-06-legal-services.png',
  'internet-commerce-services': 'service-07-digital-services.png',
  'real-estate-contracts': 'service-08-real-estate.png',
  'business-development': 'service-09-business-development.png',
  'specialized-services': 'service-10-specialized-services.png',
};

class CompanionModule {
  const CompanionModule(this.title, this.subtitle, this.image, this.icon);
  final String title;
  final String subtitle;
  final String image;
  final IconData icon;
}

const companionModules = <CompanionModule>[
  CompanionModule('پکیج‌های کارگزار', 'راهکارهای آماده و مقرون‌به‌صرفه برای شروع و توسعه کسب‌وکار', 'companion-01-packages.png', Icons.inventory_2_outlined),
  CompanionModule('استودیو طراحی', 'طراحی هویت بصری، محصولات و محتوای تخصصی', 'companion-02-design-studio.png', Icons.design_services_outlined),
  CompanionModule('حسابداری و مالی', 'مدیریت امور مالی و گزارش‌های کسب‌وکار', 'companion-03-accounting.png', Icons.calculate_outlined),
  CompanionModule('فاکتور و مدیریت فروش', 'صدور فاکتور و کنترل فرایند فروش', 'companion-04-sales-management.png', Icons.point_of_sale_outlined),
  CompanionModule('پرسنل و منابع انسانی', 'مدیریت کارکنان، حضور و غیاب و حقوق', 'companion-05-human-resources.png', Icons.groups_outlined),
  CompanionModule('قراردادها و اسناد', 'سامان‌دهی قراردادها و اسناد کسب‌وکار', 'companion-06-contracts.png', Icons.description_outlined),
  CompanionModule('تبلیغات و بازاریابی', 'ابزارهای معرفی و توسعه بازار', 'companion-07-marketing.png', Icons.campaign_outlined),
  CompanionModule('انبار و مدیریت موجودی', 'کنترل کالا، موجودی و گردش انبار', 'companion-08-inventory.png', Icons.warehouse_outlined),
  CompanionModule('خدمات و امکانات تکمیلی', 'امکانات کاربردی برای مدیریت بهتر کسب‌وکار', 'companion-09-extra-services.png', Icons.extension_outlined),
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
        child: url == null || !url.hasScheme || url.host.isEmpty
            ? _fallback()
            : Image.network(
                url.toString(),
                fit: fit,
                errorBuilder: (_, __, ___) => _fallback(),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Container(
                        color: const Color(0xFFF3F0F4),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
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

class AppBannerStrip extends StatelessWidget {
  const AppBannerStrip({super.key, required this.onNavigate, required this.onConsultation});
  final ValueChanged<int> onNavigate;
  final VoidCallback onConsultation;

  static const banners = <(String, String, int)>[
    ('banner-01-support.png', 'تماس و پشتیبانی', 3),
    ('banner-02-business-solutions.png', 'راهکارهای کسب‌وکار', 2),
    ('banner-03-packages.png', 'پکیج‌های کارگزار', 2),
    ('banner-04-free-consultation.png', 'مشاوره رایگان', -1),
    ('banner-05-services.png', 'مشاهده خدمات', 1),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 142,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: banners.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final item = banners[index];
            return SizedBox(
              width: MediaQuery.sizeOf(context).width * .78,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: item.$3 == -1
                      ? onConsultation
                      : () => onNavigate(item.$3),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppContentImage(fileName: item.$1, borderRadius: 0),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xE649334F),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(item.$2, style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12,
                          )),
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
  const CompanionContentPage({super.key, required this.onOpen});
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('همراه کسب‌وکار', style: TextStyle(
            color: Color(0xFF1E293B), fontSize: 25, fontWeight: FontWeight.w900,
          )),
          const SizedBox(height: 7),
          const Text('ابزارها و راهکارهایی برای اداره و توسعه کسب‌وکار شما.',
            style: TextStyle(color: Color(0xFF64748B), height: 1.7)),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: companionModules.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .94,
            ),
            itemBuilder: (context, index) {
              final item = companionModules[index];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onOpen(index),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: AppContentImage(
                        fileName: item.image, borderRadius: 0, fallbackIcon: item.icon,
                      )),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(11, 10, 11, 2),
                        child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12,
                            color: Color(0xFF1E293B))),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(11, 2, 11, 10),
                        child: Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, height: 1.5,
                            color: Color(0xFF64748B))),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
}

class SupportContentPage extends StatelessWidget {
  const SupportContentPage({super.key, required this.onConsultation});
  final VoidCallback onConsultation;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('تماس و پشتیبانی', style: TextStyle(
            color: Color(0xFF1E293B), fontSize: 25, fontWeight: FontWeight.w900,
          )),
          const SizedBox(height: 16),
          const AppContentImage(
            fileName: 'banner-01-support.png',
            height: 170,
            width: double.infinity,
            borderRadius: 18,
            fallbackIcon: Icons.support_agent_outlined,
          ),
          const SizedBox(height: 16),
          const Text('پشتیبانی کارگزار', style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF49334F),
          )),
          const SizedBox(height: 8),
          const Text(
            'برای پیگیری درخواست‌ها، دریافت راهنمایی و طرح پرسش درباره خدمات، از مسیر پشتیبانی اقدام کنید.',
            style: TextStyle(color: Color(0xFF64748B), height: 1.9),
          ),
          const SizedBox(height: 14),
          Card(
            color: Colors.white,
            child: ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFFC62828)),
              title: const Text('درخواست مشاوره رایگان'),
              subtitle: const Text('ثبت درخواست برای ارتباط با کارشناس'),
              trailing: const Icon(Icons.chevron_left),
              onTap: onConsultation,
            ),
          ),
          const Card(
            color: Colors.white,
            child: ListTile(
              leading: Icon(Icons.lock_outline, color: Color(0xFF49334F)),
              title: Text('خدمات غیرحضوری و سراسری'),
              subtitle: Text('دریافت و پیگیری خدمات بدون مراجعه حضوری'),
            ),
          ),
        ],
      );
}

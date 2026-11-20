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

class CompanionModule {
  const CompanionModule(this.title, this.subtitle, this.image, this.icon);
  final String title;
  final String subtitle;
  final String image;
  final IconData icon;
}

const companionModules = <CompanionModule>[
  CompanionModule('پکیج‌های کارگزار', 'راهکارهای آماده و مقرون‌به‌صرفه برای شروع و توسعه کسب‌وکار', 'companion-01-packages.webp', Icons.inventory_2_outlined),
  CompanionModule('استودیو طراحی', 'طراحی هویت بصری، محصولات و محتوای تخصصی', 'companion-02-design-studio.webp', Icons.design_services_outlined),
  CompanionModule('حسابداری و مالی', 'مدیریت امور مالی و گزارش‌های کسب‌وکار', 'companion-03-accounting.webp', Icons.calculate_outlined),
  CompanionModule('فاکتور و مدیریت فروش', 'صدور فاکتور و کنترل فرایند فروش', 'companion-04-sales-management.webp', Icons.point_of_sale_outlined),
  CompanionModule('پرسنل و منابع انسانی', 'مدیریت کارکنان، حضور و غیاب و حقوق', 'companion-05-human-resources.webp', Icons.groups_outlined),
  CompanionModule('قراردادها و اسناد', 'سامان‌دهی قراردادها و اسناد کسب‌وکار', 'companion-06-contracts.webp', Icons.description_outlined),
  CompanionModule('تبلیغات و بازاریابی', 'ابزارهای معرفی و توسعه بازار', 'companion-07-marketing.webp', Icons.campaign_outlined),
  CompanionModule('انبار و مدیریت موجودی', 'کنترل کالا، موجودی و گردش انبار', 'companion-08-inventory.webp', Icons.warehouse_outlined),
  CompanionModule('خدمات و امکانات تکمیلی', 'امکانات کاربردی برای مدیریت بهتر کسب‌وکار', 'companion-09-extra-services.webp', Icons.extension_outlined),
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
    required this.onOpen,
    required this.onNavigate,
    required this.onConsultation,
  });

  final ValueChanged<int> onOpen;
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
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: companionModules.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                final item = companionModules[index];
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onOpen(index),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: AppContentImage(
                            fileName: item.image,
                            borderRadius: 0,
                            fallbackIcon: item.icon,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(9),
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
     _SupportAction(icon:Icons.phone_in_talk_outlined,title:'تماس تلفنی',subtitle:'تماس مستقیم با کارشناسان کارگزار',onTap:()=>_launch(Uri(scheme:'tel',path:'09365952800'),context)),
     const SizedBox(height:7),
     _SupportAction(icon:Icons.email_outlined,title:'ارتباط از طریق ایمیل',subtitle:'ارسال پیام به info@kargozarr.ir',onTap:()=>_launch(Uri(scheme:'mailto',path:'info@kargozarr.ir',queryParameters:{'subject':'ارتباط با پشتیبانی کارگزار'}),context)),
     const SizedBox(height:7),
     const _SupportAction(icon:Icons.confirmation_number_outlined,title:'تماس با کارشناس',subtitle:'دریافت راهنمایی درباره خدمات کارگزار',onTap:()=>_launch(Uri(scheme:'tel',path:'09365952800'),context)),
     const SizedBox(height:7),
     const _SupportAction(icon:Icons.smart_toy_outlined,title:'ارتباط با پشتیبانی',subtitle:'تماس مستقیم با کارشناسان کارگزار',onTap:()=>_launch(Uri(scheme:'tel',path:'09365952800'),context)),
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

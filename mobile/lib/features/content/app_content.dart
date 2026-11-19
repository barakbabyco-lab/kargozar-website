import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'support_actions_panel.dart';

const serviceCategoryImages = <String, String>{
  'business-licenses': 'service-01-business-permits.svg',
  'trademark-intellectual-property': 'service-02-brand-registration.svg',
  'company-registration': 'service-03-company-registration.svg',
  'supplementary-certificates': 'service-04-certifications.svg',
  'banking-services': 'service-05-banking.svg',
  'legal-contract-services': 'service-06-legal-services.svg',
  'internet-commerce-services': 'service-07-digital-services.svg',
  'real-estate-contracts': 'service-08-real-estate.svg',
  'business-development': 'service-09-business-development.svg',
  'specialized-services': 'service-10-specialized-services.svg',
};

class CompanionModule {
  const CompanionModule(this.title, this.subtitle, this.image, this.icon);
  final String title, subtitle, image;
  final IconData icon;
}
const companionModules = <CompanionModule>[
  CompanionModule('پکیج‌های کارگزار','راهکارهای آماده برای شروع و توسعه کسب‌وکار','companion-01-packages.svg',Icons.inventory_2_outlined),
  CompanionModule('استودیو طراحی','طراحی هویت بصری و محتوای تخصصی','companion-02-design-studio.svg',Icons.design_services_outlined),
  CompanionModule('حسابداری و مالی','مدیریت امور مالی','companion-03-accounting.svg',Icons.calculate_outlined),
  CompanionModule('فاکتور و مدیریت فروش','صدور فاکتور و کنترل فروش','companion-04-sales-management.svg',Icons.point_of_sale_outlined),
  CompanionModule('پرسنل و منابع انسانی','مدیریت کارکنان و حقوق','companion-05-human-resources.svg',Icons.groups_outlined),
  CompanionModule('قراردادها و اسناد','سامان‌دهی اسناد کسب‌وکار','companion-06-contracts.svg',Icons.description_outlined),
  CompanionModule('تبلیغات و بازاریابی','ابزارهای توسعه بازار','companion-07-marketing.svg',Icons.campaign_outlined),
  CompanionModule('انبار و مدیریت موجودی','کنترل کالا و گردش انبار','companion-08-inventory.svg',Icons.warehouse_outlined),
  CompanionModule('خدمات و امکانات تکمیلی','امکانات کاربردی مدیریت کسب‌وکار','companion-09-extra-services.svg',Icons.extension_outlined),
];

class AppContentImage extends StatelessWidget {
  const AppContentImage({super.key,required this.fileName,this.height,this.width,this.fit=BoxFit.cover,this.fallbackIcon=Icons.image_outlined,this.borderRadius=14});
  final String fileName; final double? height,width; final BoxFit fit; final IconData fallbackIcon; final double borderRadius;
  @override Widget build(BuildContext context) {
    final name=fileName.replaceAll('.png','.svg');
    return ClipRRect(borderRadius:BorderRadius.circular(borderRadius),child:SizedBox(height:height,width:width,
      child:SvgPicture.asset('assets/$name',fit:fit,placeholderBuilder:(_)=>_fallback(),),
    ));
  }
  Widget _fallback()=>Container(color:const Color(0xFFFFF1F2),alignment:Alignment.center,child:Icon(fallbackIcon,color:const Color(0xFF4B0082),size:34));
}

class AppBannerStrip extends StatefulWidget {
  const AppBannerStrip({super.key,required this.onNavigate,required this.onConsultation});
  final ValueChanged<int> onNavigate; final VoidCallback onConsultation;
  static const banners=< (String,String,int) >[
    ('banner-01-support.svg','تماس و پشتیبانی',3),
    ('banner-02-business-solutions.svg','راهکارهای کسب‌وکار',2),
    ('banner-03-packages.svg','پکیج‌های کارگزار',4),
    ('banner-04-free-consultation.svg','مشاوره رایگان',-1),
    ('banner-05-services.svg','مشاهده خدمات',1),
  ];
  @override State<AppBannerStrip> createState()=>_AppBannerStripState();
}
class _AppBannerStripState extends State<AppBannerStrip> {
  late final PageController _controller; Timer? _timer; int _page=0;
  @override void initState(){super.initState();_controller=PageController(viewportFraction:1);_timer=Timer.periodic(const Duration(seconds:4),(_){if(!mounted)return;_page=(_page+1)%AppBannerStrip.banners.length;_controller.animateToPage(_page,duration:const Duration(milliseconds:450),curve:Curves.easeInOut);});}
  @override void dispose(){_timer?.cancel();_controller.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>SizedBox(height:112,width:double.infinity,child:PageView.builder(controller:_controller,itemCount:AppBannerStrip.banners.length,onPageChanged:(v)=>_page=v,itemBuilder:(context,index){final item=AppBannerStrip.banners[index];return Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Material(color:Colors.white,borderRadius:BorderRadius.circular(16),clipBehavior:Clip.antiAlias,child:InkWell(onTap:item.$3==-1?widget.onConsultation:()=>widget.onNavigate(item.$3),child:Stack(fit:StackFit.expand,children:[AppContentImage(fileName:item.$1,borderRadius:0),Align(alignment:Alignment.bottomRight,child:Container(margin:const EdgeInsets.all(9),padding:const EdgeInsets.symmetric(horizontal:12,vertical:6),decoration:BoxDecoration(color:const Color(0xE64B0082),borderRadius:BorderRadius.circular(9)),child:Text(item.$2,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:12))))])));} ));
}

class CompanionContentPage extends StatelessWidget {
  const CompanionContentPage({super.key,required this.onOpen,required this.onNavigate,required this.onConsultation});
  final ValueChanged<int> onOpen; final ValueChanged<int> onNavigate; final VoidCallback onConsultation;
  @override Widget build(BuildContext context)=>Column(children:[
    const SizedBox(height:8),AppBannerStrip(onNavigate:onNavigate,onConsultation:onConsultation),
    const Padding(padding:EdgeInsets.fromLTRB(16,8,16,4),child:Align(alignment:Alignment.centerRight,child:Text('ابزارهای کسب‌وکار',style:TextStyle(fontSize:14,fontWeight:FontWeight.w800,color:Color(0xFF4B0082))))),
    Expanded(child:GridView.builder(padding:const EdgeInsets.fromLTRB(16,4,16,10),itemCount:companionModules.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:1.38),itemBuilder:(context,index){final item=companionModules[index];return Material(color:Colors.white,borderRadius:BorderRadius.circular(14),clipBehavior:Clip.antiAlias,child:InkWell(onTap:()=>onOpen(index),child:Column(children:[Expanded(child:AppContentImage(fileName:item.image,borderRadius:0)),Padding(padding:const EdgeInsets.symmetric(horizontal:7,vertical:7),child:Text(item.title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:11,color:Color(0xFF263238))))])));})),
  ]);
}

class SupportContentPage extends StatelessWidget {
  const SupportContentPage({super.key,required this.onConsultation,required this.onNavigate});
  final VoidCallback onConsultation; final ValueChanged<int> onNavigate;
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.only(top:8,bottom:12),children:[
    AppBannerStrip(onNavigate:onNavigate,onConsultation:onConsultation),
    const Padding(padding:EdgeInsets.fromLTRB(16,8,16,8),child:Text('پشتیبانی',style:TextStyle(fontSize:14,fontWeight:FontWeight.w800,color:Color(0xFF4B0082)))),
    const SupportActionsPanel(),
    Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Card(color:Colors.white,child:ListTile(leading:const Icon(Icons.lightbulb_outline,color:Color(0xFF4B0082)),title:const Text('درخواست مشاوره رایگان'),onTap:onConsultation))),
  ]);
}

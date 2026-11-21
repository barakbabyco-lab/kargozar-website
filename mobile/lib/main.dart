import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'core/network/kargozar_api_client.dart';
import 'features/auth/customer_session.dart';
import 'features/catalog/service_catalog_repository.dart';
import 'features/requests/customer_request_repository.dart';
import 'features/catalog/service_taxonomy.dart';
import 'features/content/app_content.dart';

void main() {
  runApp(const KargozarApp());
}

const _navy = Color(0xFF4B0082); // برند مکمل: بادمجانی تیره
const _brandRed = Color(0xFFE30613); // رنگ اصلی برند: قرمز
const _ink = Color(0xFF1E293B);
const _muted = Color(0xFF64748B);
const _canvas = Color(0xFFFFFFFF);

class KargozarApp extends StatefulWidget {
 const KargozarApp({super.key,this.apiClient}); final KargozarApiClient? apiClient;
 @override State<KargozarApp> createState()=>_KargozarAppState();
}
class _KargozarAppState extends State<KargozarApp>{
 late final KargozarApiClient _api; late final CustomerSession _session; late final CustomerRequestRepository _requests;
 bool _loading=true,_signedIn=false;
 @override void initState(){super.initState();_api=widget.apiClient??KargozarApiClient();_session=CustomerSession(_api);_requests=CustomerRequestRepository(_api);_restore();}
 Future<void> _restore()async{try{final ok=await _session.restore();if(mounted)setState(()=>_signedIn=ok);}catch(_){}finally{if(mounted)setState(()=>_loading=false);}}
 final _navigatorKey=GlobalKey<NavigatorState>();
 Future<bool> _login()async{final dialogContext=_navigatorKey.currentContext;if(dialogContext==null)return false;final ok=await showDialog<bool>(context:dialogContext,barrierDismissible:false,builder:(_)=>OtpDialog(session:_session));final authenticated=ok==true&&_session.isAuthenticated;if(mounted)setState(()=>_signedIn=authenticated);return authenticated;}
 Future<void> _logout()async{try{await _session.signOut();}catch(_){}if(mounted)setState(()=>_signedIn=false);}
 @override void dispose(){_api.close();super.dispose();}
 @override Widget build(BuildContext context)=>MaterialApp(
 navigatorKey:_navigatorKey,
 debugShowCheckedModeBanner:false,title:'کارگزار',
 theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:_canvas,colorScheme:ColorScheme.fromSeed(seedColor:_brandRed,primary:_brandRed,secondary:_navy,surface:Colors.white),fontFamily:'Roboto',
 appBarTheme:const AppBarTheme(backgroundColor:_canvas,foregroundColor:_ink,centerTitle:false,elevation:0),
 inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:Color(0xFFE2E8F0))),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:Color(0xFFE2E8F0))))),
 home:Directionality(textDirection:TextDirection.rtl,child:_loading?const Scaffold(body:Center(child:CircularProgressIndicator())):MainShell(api:_api,requests:_requests,signedIn:_signedIn,onLogin:_login,onLogout:_logout)),
 );
}
class OtpDialog extends StatefulWidget{
 const OtpDialog({super.key,required this.session});final CustomerSession session;
 @override State<OtpDialog> createState()=>_OtpDialogState();
}
class _OtpDialogState extends State<OtpDialog>{
 final _mobile=TextEditingController(),_code=TextEditingController();bool _requested=false,_busy=false;String? _error;
 @override void dispose(){_mobile.dispose();_code.dispose();super.dispose();}
 Future<void> _submit()async{
 final mobile=_mobile.text.trim();
 if(!RegExp(r'^09\d{9}$').hasMatch(mobile)){setState(()=>_error='شماره موبایل معتبر وارد کن.');return;}
 if(_requested&&!RegExp(r'^\d{4,8}$').hasMatch(_code.text.trim())){setState(()=>_error='کد ورود معتبر نیست.');return;}
 setState(() { _busy = true; _error = null; });
 try{if(!_requested){await widget.session.requestOtp(mobile);if(mounted)setState(()=>_requested=true);}else{await widget.session.verifyOtp(mobile:mobile,code:_code.text.trim());if(mounted)Navigator.pop(context,true);}}
 on KargozarApiException catch(e){if(mounted)setState(()=>_error=e.message);}catch(_){if(mounted)setState(()=>_error='ارتباط با سرور برقرار نشد.');}finally{if(mounted)setState(()=>_busy=false);}
 }
 @override Widget build(BuildContext context)=>AlertDialog(title:const Text('ورود به کارگزار'),content:Column(mainAxisSize:MainAxisSize.min,children:[
 const Text('برای ثبت و پیگیری درخواست‌ها، شماره موبایل خود را تأیید کن.'),
 TextField(controller:_mobile,enabled:!_requested,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'شماره موبایل')),
 if(_requested)TextField(controller:_code,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'کد یک‌بارمصرف')),
 if(_error!=null)Text(_error!,style:const TextStyle(color:Colors.red)),
 ]),actions:[
 TextButton(onPressed:_busy?null:()=>Navigator.pop(context,false),child:const Text('انصراف')),
 FilledButton(onPressed:_busy?null:_submit,child:_busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):Text(_requested?'تأیید و ورود':'دریافت کد')),
 ]);
}

class ServiceItem {
  const ServiceItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.category,
    this.apiId,
    this.requirements = const [],
    this.estimatedDays,
    this.basePrice,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String category;
  final String? apiId;
  final List<String> requirements;
  final int? estimatedDays;
  final num? basePrice;
}

const services = <ServiceItem>[
  ServiceItem(
    title: 'دریافت جواز کسب',
    subtitle: 'راهنمایی و پیگیری مراحل صدور مجوز',
    icon: Icons.storefront_outlined,
    category: 'مجوزها',
  ),
  ServiceItem(
    title: 'ثبت برند و علامت تجاری',
    subtitle: 'ثبت نام و نشان تجاری در مسیر قانونی',
    icon: Icons.verified_outlined,
    category: 'ثبت و مالکیت',
  ),
  ServiceItem(
    title: 'دریافت کارت بازرگانی',
    subtitle: 'بررسی شرایط و تشکیل پرونده',
    icon: Icons.import_export_rounded,
    category: 'مجوزها',
  ),
  ServiceItem(
    title: 'اینماد و راه‌اندازی فروشگاه',
    subtitle: 'نماد اعتماد، درگاه پرداخت و وب‌سایت',
    icon: Icons.shopping_bag_outlined,
    category: 'خدمات آنلاین',
  ),
  ServiceItem(
    title: 'پرونده مالیاتی',
    subtitle: 'تشکیل و پیگیری پرونده مالیاتی',
    icon: Icons.account_balance_outlined,
    category: 'مالی و اداری',
  ),
  ServiceItem(
    title: 'تنظیم قرارداد',
    subtitle: 'قراردادهای کاری و پیمانکاری',
    icon: Icons.description_outlined,
    category: 'قراردادها',
  ),
  ServiceItem(
    title: 'کارت بهداشت',
    subtitle: 'راهنمایی و پیگیری مدارک لازم',
    icon: Icons.health_and_safety_outlined,
    category: 'مجوزها',
  ),
  ServiceItem(
    title: 'طراحی تیزر تبلیغاتی',
    subtitle: 'معرفی حرفه‌ای کسب‌وکار شما',
    icon: Icons.movie_creation_outlined,
    category: 'تبلیغات',
  ),
];

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.api, required this.requests, required this.signedIn, required this.onLogin, required this.onLogout});
  final KargozarApiClient api;
  final CustomerRequestRepository requests;
  final bool signedIn;
  final Future<bool> Function() onLogin;
  final VoidCallback onLogout;
  @override State<MainShell> createState() => _MainShellState();
}
class _MainShellState extends State<MainShell> {
  int _index = 1, _revision = 0;
  late final PageController _pageController = PageController(initialPage: _index);
  void _goToTab(int index) {
    if (index < 0 || index >= 4) return;
    if (_index != index) setState(() => _index = index);
    if (_pageController.hasClients && _pageController.page?.round() != index) {
      _pageController.animateToPage(index, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
    }
  }
  @override
  void dispose() { _pageController.dispose(); super.dispose(); }
  Future<void> _request(ServiceItem service) async {
    final id = service.apiId;
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ثبت آنلاین این خدمت پس از اتصال کاتالوگ سرور فعال می‌شود.')));
      return;
    }
    if (!widget.signedIn) {
      final ok = await widget.onLogin();
      if (!ok || !mounted) return;
    }
    final note = await showDialog<String>(context: context, builder: (ctx) {
      final controller = TextEditingController();
      return AlertDialog(
        title: Text('درخواست ${service.title}'),
        content: TextField(controller: controller, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'توضیحات درخواست (اختیاری)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('ادامه و ثبت درخواست')),
        ],
      );
    });
    if (note == null || !mounted) return;
    final key = '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
    try {
      final result = await widget.requests.create(serviceId: id, customerNote: note, idempotencyKey: key);
      if (!mounted) return;
      setState(() => _revision++);
      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('درخواست ثبت شد'),
        content: Text('کد پیگیری: ${result.trackingCode}'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('متوجه شدم'))],
      ));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(error))));
    }
  }
  Future<void> _showRequests() async {
    final authenticated = widget.signedIn || await widget.onLogin();
    if (!authenticated || !mounted) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('درخواست‌های من')),
        body: RequestsPage(repository: widget.requests, signedIn: true, onLogin: widget.onLogin, refreshRevision: _revision),
      ),
    )));
  }
  Future<void> _showCategoryChildren(ServiceCategory category) async {
    if (category.children.isEmpty) {
      await _openCategoryDetail(category);
      return;
    }
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .68,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(category.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _ink)),
              const SizedBox(height: 10),
              Expanded(child: ListView.separated(
                itemCount: category.children.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final child = category.children[index];
                  return _ServiceCategoryAction(
                    icon: _serviceCategoryIcon(child.slug),
                    title: child.name,
                    subtitle: child.children.isEmpty ? 'مشاهده توضیحات خدمت' : 'مشاهده توضیحات یا زیرشاخه‌ها',
                    hasChildren: child.children.isNotEmpty,
                    onDetails: () { Navigator.pop(sheetContext); _openCategoryDetail(child); },
                    onExpand: child.children.isEmpty ? null : () { Navigator.pop(sheetContext); _showCategoryChildren(child); },
                  );
                },
              )),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _openCategoryDetail(ServiceCategory category) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: ServiceCategoryDetailPage(
          category: category,
          onBrowseServices: () => _showCategoryServices(category),
        ),
      ),
    ));
  }

  Future<void> _showCategoryServices(ServiceCategory category) async {
    try {
      final items = await ServiceCatalogRepository(widget.api).getServices(category: category.slug);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (sheetContext) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * .72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _ink)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: items.isEmpty
                        ? const EmptyState(
                            icon: Icons.inbox_outlined,
                            title: 'خدمتی در این بخش ثبت نشده است',
                            subtitle: 'خدمات این دسته پس از تکمیل کاتالوگ نمایش داده می‌شوند.',
                          )
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, index) => ServiceListTile(
                              service: _serviceItemFromCatalog(items[index]),
                              onRequest: _request,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorText(error))),
        );
      }
    }

  }

  void _showConsultation() {
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('مشاوره رایگان کارگزار'),
      content: const Text('فرم ثبت درخواست مشاوره باید به سرویس ارتباط با کارشناسان متصل شود. تا زمان اتصال، این بخش درخواست ساختگی ثبت نمی‌کند.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('متوجه شدم'))],
    ));
  }
  void _openCompanionDetail(CompanionModule module) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Directionality(textDirection: TextDirection.rtl, child: CompanionDescriptionPage(
        title: module.title, description: module.description ?? module.subtitle,
        image: module.image, icon: module.icon, points: module.points,
      )),
    ));
  }

  void _openCompanionSubmodule(CompanionModule module, CompanionSubmodule submodule) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Directionality(textDirection: TextDirection.rtl, child: CompanionDescriptionPage(
        title: submodule.title, description: submodule.description,
        image: module.image, icon: submodule.icon, points: submodule.points,
      )),
    ));
  }

  Future<void> _expandCompanion(CompanionModule module) async {
    if (module.children.isEmpty) { _openCompanionDetail(module); return; }
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) => SafeArea(child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * .68,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(module.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _ink)),
            const SizedBox(height: 10),
            Expanded(child: ListView.separated(
              itemCount: module.children.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final child = module.children[index];
                return CompanionModuleRow(
                  title: child.title, subtitle: child.description, icon: child.icon,
                  hasChildren: false,
                  onDetails: () { Navigator.pop(sheetContext); _openCompanionSubmodule(module, child); },
                );
              },
            )),
          ]),
        ),
      )),
    );
  }

  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Stack(children: [
      PageView(
        key: const ValueKey('main-tabs'),
        controller: _pageController,
        physics: const PageScrollPhysics(),
        onPageChanged: (value) => setState(() => _index = value),
        children: [
          ProfilePage(signedIn: widget.signedIn, onLogin: widget.onLogin, onLogout: widget.onLogout, onShowRequests: _showRequests, onNavigate: _goToTab),
          ServicesPage(onRequest: _request, onOpenCategoryDetails: _openCategoryDetail, onExpandCategory: _showCategoryChildren, onNavigate: (tab) { if (tab == 4) { _goToTab(2); _openCompanionDetail(companionModules[0]); } else { _goToTab(tab); } }, onConsultation: _showConsultation),
          CompanionContentPage(onOpenDetails: _openCompanionDetail, onExpand: _expandCompanion, onNavigate: (tab) { if (tab == 4) { _goToTab(2); _openCompanionDetail(companionModules[0]); } else { _goToTab(tab); } }, onConsultation: _showConsultation),
          SupportContentPage(onConsultation: _showConsultation, onNavigate: _goToTab),
        ],
      ),
      Positioned(right: 14, bottom: 8, child: SupportChatLauncher(api: widget.api)),
    ])),
    bottomNavigationBar: Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _brandRed, width: 2)),
      ),
      child: NavigationBar(
        height: 62,
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFF4EEFA),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) => TextStyle(
          color: states.contains(WidgetState.selected) ? _brandRed : _navy,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        )),
        selectedIndex: _index,
        onDestinationSelected: _goToTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.person_outline_rounded, color: _navy, size: 20), selectedIcon: Icon(Icons.person_rounded, color: _brandRed, size: 20), label: 'حساب کاربری من'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined, color: _navy, size: 20), selectedIcon: Icon(Icons.grid_view_rounded, color: _brandRed, size: 20), label: 'خدمات'),
          NavigationDestination(icon: Icon(Icons.business_center_outlined, color: _navy, size: 20), selectedIcon: Icon(Icons.business_center_rounded, color: _brandRed, size: 20), label: 'همراه کسب‌وکار'),
          NavigationDestination(icon: Icon(Icons.support_agent_outlined, color: _navy, size: 20), selectedIcon: Icon(Icons.support_agent_rounded, color: _brandRed, size: 20), label: 'تماس و پشتیبانی'),
        ],
      ),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onRequest, required this.onBrowse});
  final Future<void> Function(ServiceItem service) onRequest;
  final VoidCallback onBrowse;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final KargozarApiClient _api;
  late final ServiceCatalogRepository _catalog;
  late Future<List<CatalogService>> _popularServices;
  bool _apiConfigured = false;

  @override
  void initState() {
    super.initState();
    _api = KargozarApiClient();
    _catalog = ServiceCatalogRepository(_api);
    _apiConfigured = const String.fromEnvironment('API_BASE_URL').trim().isNotEmpty;
    _popularServices = _apiConfigured
        ? _catalog.getServices()
        : Future.value(const <CatalogService>[]);
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _navy,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.handshake_outlined,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('کارگزار', style: TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w900, color: _navy)),
                Text('همراه مطمئن کسب‌وکار شما',
                    style: TextStyle(fontSize: 11, color: _muted)),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _showInfo(context),
              icon: const Icon(Icons.notifications_none_rounded),
              tooltip: 'اعلان‌ها',
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_navy, Color(0xFF254D70)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('شروع یک کسب‌وکار،\nبا مسیر روشن‌تر',
                  style: TextStyle(
                    color: Colors.white, fontSize: 23,
                    height: 1.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 9),
              const Text(
                'خدمات اداری و کسب‌وکار را آنلاین درخواست کنید و مراحل را پیگیری کنید.',
                style: TextStyle(color: Color(0xFFDCE7F1), height: 1.8)),
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _navy,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 13),
                ),
                onPressed: widget.onBrowse,
                child: const Text('مشاهده خدمات'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        const SectionHeading(title: 'خدمات پرکاربرد', action: 'مشاهده همه'),
        const SizedBox(height: 13),
        FutureBuilder<List<CatalogService>>(
          future: _popularServices,
          builder: (context, snapshot) {
            final remote = snapshot.data ?? const <CatalogService>[];
            final items = _apiConfigured && snapshot.hasData
                ? remote.take(4).map(_serviceItemFromCatalog).toList()
                : services.take(4).toList();
            if (_apiConfigured && snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (_apiConfigured && snapshot.hasError) {
              return Column(
                children: [
                  const Text('دریافت خدمات پرکاربرد ممکن نشد.',
                      style: TextStyle(color: _muted, fontSize: 12)),
                  TextButton(
                    onPressed: () => setState(
                      () => _popularServices = _catalog.getServices(),
                    ),
                    child: const Text('تلاش دوباره'),
                  ),
                ],
              );
            }
            if (_apiConfigured && items.isEmpty) {
              return const Text('هنوز خدمتی برای نمایش ثبت نشده است.',
                  style: TextStyle(color: _muted, fontSize: 12));
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.28,
              ),
              itemBuilder: (context, index) =>
                  ServiceCard(service: items[index], onRequest: widget.onRequest),
            );
          },
        ),
        const SizedBox(height: 25),
        const SectionHeading(title: 'چطور کار می‌کند؟'),
        const SizedBox(height: 13),
        const StepTile(
          number: '۱',
          title: 'خدمت موردنظرت را انتخاب کن',
          subtitle: 'جزئیات و شرایط خدمت را ببین.',
        ),
        const StepTile(
          number: '۲',
          title: 'درخواستت را ثبت کن',
          subtitle: 'کارشناس برای بررسی با تو هماهنگ می‌شود.',
        ),
        const StepTile(
          number: '۳',
          title: 'آنلاین پیگیری کن',
          subtitle: 'وضعیت درخواست و مراحل انجام را ببین.',
        ),
        const SizedBox(height: 12),
        if (!_apiConfigured)
          const Text(
            'نسخه آزمایشی — فهرست خدمات این بخش نمونه است و ثبت واقعی از سرور انجام می‌شود.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 11),
          ),
      ],
    );
  }
}

class ServicesPage extends StatefulWidget {
  const ServicesPage({
    super.key, required this.onRequest, required this.onOpenCategoryDetails,
    required this.onExpandCategory, required this.onNavigate, required this.onConsultation,
  });
  final Future<void> Function(ServiceItem service) onRequest;
  final ValueChanged<ServiceCategory> onOpenCategoryDetails;
  final ValueChanged<ServiceCategory> onExpandCategory;
  final ValueChanged<int> onNavigate;
  final VoidCallback onConsultation;
  @override State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.zero,
    children: [
      AppBannerStrip(onNavigate: widget.onNavigate, onConsultation: widget.onConsultation),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(children: [
          for (var i = 0; i < serviceTaxonomy.length; i++) ...[
            _ServiceCategoryAction(
              icon: _serviceCategoryIcon(serviceTaxonomy[i].slug),
              title: serviceTaxonomy[i].name,
              subtitle: 'مشاهده توضیحات یا زیرشاخه‌ها',
              hasChildren: serviceTaxonomy[i].children.isNotEmpty,
              onDetails: () => widget.onOpenCategoryDetails(serviceTaxonomy[i]),
              onExpand: () => widget.onExpandCategory(serviceTaxonomy[i]),
            ),
            if (i != serviceTaxonomy.length - 1) const SizedBox(height: 7),
          ],
        ]),
      ),
      const SizedBox(height: 16),
    ],
  );
}

IconData _serviceCategoryIcon(String slug) {
  switch (slug) {
    case 'business-licenses': return Icons.storefront_outlined;
    case 'trademark-intellectual-property': return Icons.verified_outlined;
    case 'company-registration': return Icons.apartment_outlined;
    case 'supplementary-certificates': return Icons.fact_check_outlined;
    case 'banking-services': return Icons.account_balance_outlined;
    case 'legal-contract-services': return Icons.gavel_outlined;
    case 'internet-commerce-services': return Icons.language_rounded;
    case 'real-estate-contracts': return Icons.real_estate_agent_outlined;
    case 'business-development': return Icons.trending_up_rounded;
    case 'specialized-services': return Icons.workspace_premium_outlined;
    default: return Icons.grid_view_rounded;
  }
}

class _ServiceCategoryAction extends StatelessWidget {
  const _ServiceCategoryAction({
    required this.icon, required this.title, required this.subtitle,
    required this.hasChildren, required this.onDetails, this.onExpand,
  });
  final IconData icon;
  final String title;
  final String subtitle;
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
      child: Row(children: [
        Expanded(child: InkWell(
          onTap: onDetails,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(children: [
              Icon(icon, color: const Color(0xFFE30613), size: 22),
              const SizedBox(width: 12),
              Expanded(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.w800)),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                ],
              )),
            ]),
          ),
        )),
        if (hasChildren)
          IconButton(
            tooltip: 'نمایش زیرشاخه‌ها',
            onPressed: onExpand,
            icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF64748B), size: 21),
          )
        else
          const SizedBox(width: 12),
      ]),
    ),
  );
}

ServiceItem _serviceItemFromCatalog(CatalogService item) => ServiceItem(
  title: item.title,
  subtitle: item.description ?? item.categoryName ?? '',
  category: item.categoryName ?? 'سایر خدمات',
  icon: _iconForCategory(item.categoryName),
  apiId: item.id,
  requirements: item.requirements,
  estimatedDays: item.estimatedDays,
  basePrice: item.basePrice,
);

IconData _iconForCategory(String? category) {
  final value = category ?? '';
  if (value.contains('مجوز') || value.contains('بهداشتی')) return Icons.storefront_outlined;
  if (value.contains('ثبت') || value.contains('برند')) return Icons.verified_outlined;
  if (value.contains('بانک')) return Icons.account_balance_outlined;
  if (value.contains('قرارداد') || value.contains('حقوقی')) return Icons.description_outlined;
  if (value.contains('آنلاین') || value.contains('اینترنت')) return Icons.shopping_bag_outlined;
  return Icons.work_outline_rounded;
}

class RequestsPage extends StatefulWidget {
 const RequestsPage({super.key,required this.repository,required this.signedIn,required this.onLogin,required this.refreshRevision});
 final CustomerRequestRepository repository;final bool signedIn;final VoidCallback onLogin;final int refreshRevision;
 @override State<RequestsPage> createState()=>_RequestsPageState();
}
class _RequestsPageState extends State<RequestsPage>{
 late Future<List<CustomerServiceRequest>> _future;
 @override void initState(){super.initState();_future=widget.signedIn?widget.repository.getMine():Future.value(const <CustomerServiceRequest>[]);}
 @override void didUpdateWidget(covariant RequestsPage old){super.didUpdateWidget(old);if(widget.signedIn&&(!old.signedIn||old.refreshRevision!=widget.refreshRevision)){_future=widget.repository.getMine();}else if(!widget.signedIn&&old.signedIn){_future=Future.value(const <CustomerServiceRequest>[]);}}
 void _reload()=>setState(()=>_future=widget.repository.getMine());
 @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(20),children:[
 const Text('درخواست‌های من',style:TextStyle(color:_ink,fontSize:25,fontWeight:FontWeight.w900)),const SizedBox(height:8),const Text('وضعیت درخواست‌هایت را از این قسمت پیگیری می‌کنی.',style:TextStyle(color:_muted,height:1.8)),const SizedBox(height:24),
 if(!widget.signedIn)Column(children:[const EmptyState(icon:Icons.lock_outline,title:'برای مشاهده درخواست‌ها وارد شو',subtitle:'پس از ورود، درخواست‌های ثبت‌شده و آخرین وضعیت آن‌ها نمایش داده می‌شود.'),const SizedBox(height:12),FilledButton(onPressed:widget.onLogin,child:const Text('ورود / ثبت‌نام'))])
 else FutureBuilder<List<CustomerServiceRequest>>(future:_future,builder:(context,snap){
 if(snap.hasError)return Column(children:[EmptyState(icon:Icons.cloud_off_outlined,title:'دریافت درخواست‌ها ممکن نشد',subtitle:errorText(snap.error)),TextButton(onPressed:_reload,child:const Text('تلاش دوباره'))]);
 if(!snap.hasData)return const Padding(padding:EdgeInsets.all(24),child:Center(child:CircularProgressIndicator()));
 if(snap.data!.isEmpty)return const EmptyState(icon:Icons.inbox_outlined,title:'هنوز درخواستی ثبت نکرده‌ای',subtitle:'بعد از ثبت درخواست، کد پیگیری و آخرین وضعیت اینجا نمایش داده می‌شود.');
 return Column(children:snap.data!.map((r)=>Card(color:Colors.white,child:ListTile(title:Text(r.serviceTitle??r.trackingCode,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text('کد پیگیری: ${r.trackingCode}\nوضعیت: ${requestStatusLabel(r.status)}'),isThreeLine:true,trailing:const Icon(Icons.chevron_left_rounded),onTap:()=>_showRequestDetails(context,r)))).toList());
 }),
 ]);
}
void _showRequestDetails(BuildContext context,CustomerServiceRequest request){showModalBottomSheet<void>(context:context,isScrollControlled:true,backgroundColor:Colors.white,shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(24))),builder:(ctx)=>SafeArea(child:Padding(padding:const EdgeInsets.all(20),child:ListView(shrinkWrap:true,children:[Text('پیگیری ${request.trackingCode}',style:const TextStyle(fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:10),Text('وضعیت فعلی: ${requestStatusLabel(request.status)}'),if(request.customerNote?.isNotEmpty==true)Text('توضیحات: ${request.customerNote}'),const SizedBox(height:18),const Text('آخرین رویدادها',style:TextStyle(fontWeight:FontWeight.w800)),if(request.events.isEmpty)const Text('هنوز رویدادی برای این درخواست ثبت نشده است.'),...request.events.map((e)=>ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.timeline_rounded,color:_brandRed),title:Text(e.publicMessage??requestStatusLabel(e.status)),subtitle:Text(requestStatusLabel(e.status))))]))));}
String requestStatusLabel(String status)=>switch(status){'submitted'=>'ثبت‌شده','reviewing'=>'در حال بررسی','awaiting_customer'=>'نیازمند اقدام شما','in_progress'=>'در حال انجام','completed'=>'تکمیل‌شده','rejected'=>'ردشده','cancelled'=>'لغوشده',_=>status};
class ProfilePage extends StatelessWidget {
 const ProfilePage({super.key,required this.signedIn,required this.onLogin,required this.onLogout,required this.onShowRequests,required this.onNavigate});
 final bool signedIn;
 final VoidCallback onLogin,onLogout,onShowRequests;
 final ValueChanged<int> onNavigate;

 @override
 Widget build(BuildContext context)=>ListView(padding:EdgeInsets.zero,children:[
   AppBannerStrip(onNavigate:onNavigate,onConsultation:()=>onNavigate(3)),
   const SizedBox(height:12),
   Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Column(children:[
     _ProfileAction(icon:Icons.receipt_long_outlined,title:'درخواست‌های من',onTap:onShowRequests),
     const SizedBox(height:7),
     _ProfileAction(icon:signedIn?Icons.logout_rounded:Icons.login_rounded,title:signedIn?'خروج از حساب':'ورود / ثبت‌نام',onTap:signedIn?onLogout:onLogin),
     const SizedBox(height:7),
     _ProfileAction(icon:Icons.verified_user_outlined,title:'احراز هویت',onTap:()=>showDialog<void>(context:context,builder:(ctx)=>AlertDialog(title:const Text('احراز هویت'),content:const Text('در این بخش، دریافت و ارسال مدارک و احراز هویت تصویری به‌تدریج فعال می‌شود.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('متوجه شدم'))]))),
   ])),
 ]);
}

class _ProfileAction extends StatelessWidget {
 const _ProfileAction({required this.icon,required this.title,required this.onTap});
 final IconData icon; final String title; final VoidCallback onTap;
 @override Widget build(BuildContext context)=>Material(
   color:Colors.white,borderRadius:BorderRadius.circular(12),
   child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(12),
     child:Container(height:54,padding:const EdgeInsets.symmetric(horizontal:14),
       decoration:BoxDecoration(borderRadius:BorderRadius.circular(12),border:Border.all(color:const Color(0xFFF0B9B9))),
       child:Row(children:[Icon(icon,color:_brandRed,size:22),const SizedBox(width:12),Expanded(child:Text(title,style:const TextStyle(color:_ink,fontSize:13,fontWeight:FontWeight.w700))),const Icon(Icons.chevron_left_rounded,color:_muted,size:20)]),
     ),
   ),
 );
}

class SupportChatLauncher extends StatefulWidget {
 const SupportChatLauncher({super.key,required this.api});
 final KargozarApiClient api;
 @override State<SupportChatLauncher> createState()=>_SupportChatLauncherState();
}
class _SupportChatLauncherState extends State<SupportChatLauncher> {
 Timer? _inviteTimer; Timer? _dismissTimer; bool _showInvite=false; bool _opened=false;
 @override void initState(){super.initState();_inviteTimer=Timer(const Duration(seconds:25),(){
   if(!mounted||_opened)return;setState(()=>_showInvite=true);
   _dismissTimer=Timer(const Duration(seconds:9),(){if(mounted)setState(()=>_showInvite=false);});
 });}
 @override void dispose(){_inviteTimer?.cancel();_dismissTimer?.cancel();super.dispose();}
 Future<void> _openChat() async {
   _opened=true;setState(()=>_showInvite=false);
   if(!mounted)return;
   await showModalBottomSheet<void>(context:context,isScrollControlled:true,backgroundColor:Colors.white,
     shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(20))),
     builder:(ctx)=>SupportChatSheet(api:widget.api));
 }
 @override Widget build(BuildContext context)=>Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.end,children:[
   if(_showInvite)Container(constraints:const BoxConstraints(maxWidth:210),margin:const EdgeInsets.only(bottom:7),padding:const EdgeInsets.symmetric(horizontal:11,vertical:8),
     decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(13),border:Border.all(color:const Color(0xFFE7B4B4)),boxShadow:const [BoxShadow(color:Color(0x22000000),blurRadius:9,offset:Offset(0,3))]),
     child:const Text('سؤالی دارید؟ برای راهنمایی در کنار شما هستیم.',style:TextStyle(color:_ink,fontSize:11,height:1.5))),
   Material(color:_brandRed,shape:const CircleBorder(),elevation:4,child:InkWell(onTap:_openChat,customBorder:const CircleBorder(),child:const SizedBox(width:44,height:44,child:Icon(Icons.chat_bubble_outline_rounded,color:Colors.white,size:21)))),
 ]);
}

class SupportChatSheet extends StatefulWidget {
 const SupportChatSheet({super.key,required this.api});
 final KargozarApiClient api;
 @override State<SupportChatSheet> createState()=>_SupportChatSheetState();
}
class _SupportChatSheetState extends State<SupportChatSheet> {
 final _controller=TextEditingController();
 final _scroll=ScrollController();
 Timer? _pollTimer;
 List<Map<String,dynamic>> _messages=[];
 int? _conversationId;
 bool _busy=false;
 String? _error;
 @override void initState(){super.initState();}
 @override void dispose(){_pollTimer?.cancel();_controller.dispose();_scroll.dispose();super.dispose();}
 Future<void> _send() async {
   final body=_controller.text.trim();if(body.isEmpty||_busy)return;
   setState(()=>_busy=true);_controller.clear();
   try{
     final response=_conversationId==null
       ? await widget.api.startGuestSupportConversation(body)
       : await widget.api.sendGuestSupportMessage(_conversationId!,body);
     final data=response['data'];
     if(_conversationId==null&&data is Map<String,dynamic>){
       _conversationId=(data['id'] as num?)?.toInt();
       final initial=data['messages'];
       if(initial is List){_messages=initial.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();}
       _startPolling();
     }else if(data is Map<String,dynamic>){_messages.add(Map<String,dynamic>.from(data));}
     if(mounted)setState(()=>_error=null);
     _scrollToEnd();
   }catch(error){if(mounted){_controller.text=body;setState(()=>_error=errorText(error));}}
   finally{if(mounted)setState(()=>_busy=false);}
 }
 void _startPolling(){
   _pollTimer?.cancel();
   _pollTimer=Timer.periodic(const Duration(seconds:5),(_)=>_refresh());
 }
 Future<void> _refresh() async {
   final id=_conversationId;if(id==null||!mounted)return;
   try{
     final response=await widget.api.getGuestSupportMessages(id);
     final data=response['data'];
     if(data is List&&mounted){
       final next=data.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
       if(next.length!=_messages.length||next.isNotEmpty&&_messages.isNotEmpty&&next.last['id']!=_messages.last['id']){
         setState(()=>_messages=next);_scrollToEnd();
       }
     }
   }catch(_){}
 }
 void _scrollToEnd(){WidgetsBinding.instance.addPostFrameCallback((_){if(_scroll.hasClients)_scroll.animateTo(_scroll.position.maxScrollExtent,duration:const Duration(milliseconds:180),curve:Curves.easeOut);});}
 @override Widget build(BuildContext context)=>SizedBox(
   height:MediaQuery.sizeOf(context).height*.68,
   child:Padding(padding:EdgeInsets.fromLTRB(16,16,16,MediaQuery.viewInsetsOf(context).bottom+12),
     child:Column(children:[
       const Row(children:[Icon(Icons.smart_toy_outlined,color:_brandRed),SizedBox(width:8),Text('دستیار هوشمند کارگزار',style:TextStyle(fontSize:16,fontWeight:FontWeight.w800)),Spacer(),Text('پشتیبانی',style:TextStyle(fontSize:11,color:_muted))]),
       const Align(alignment:Alignment.centerRight,child:Text('پاسخ‌گویی خودکار؛ در صورت نیاز ارجاع به کارشناس',style:TextStyle(color:_muted,fontSize:11))),
       const Divider(height:22),
       Expanded(child:_messages.isEmpty?const Center(child:Text('سؤال خود را بنویسید تا دستیار هوشمند کارگزار راهنمایی‌تان کند.',textAlign:TextAlign.center,style:TextStyle(color:_muted,height:1.8))):ListView.builder(controller:_scroll,itemCount:_messages.length,itemBuilder:(context,index){
         final message=_messages[index];final mine=message['sender_type']=='customer';final assistant=message['sender_type']=='assistant';
         return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:Container(
           constraints:BoxConstraints(maxWidth:MediaQuery.sizeOf(context).width*.76),
           margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.symmetric(horizontal:12,vertical:9),
           decoration:BoxDecoration(color:mine?const Color(0xFFFCE8E8):assistant?const Color(0xFFF4EEFA):const Color(0xFFF1F5F9),borderRadius:BorderRadius.circular(13)),
           child:Text('${assistant?'دستیار هوشمند کارگزار\n':''}${message['body']?.toString()??''}',style:const TextStyle(fontSize:12,height:1.6)),
         ));
       })),
       if(_error!=null)Padding(padding:const EdgeInsets.only(bottom:8),child:Text(_error!,style:const TextStyle(color:Colors.red,fontSize:11))),
       Row(children:[
         Expanded(child:TextField(controller:_controller,minLines:1,maxLines:3,textInputAction:TextInputAction.send,onSubmitted:(_)=>_send(),decoration:const InputDecoration(hintText:'پیام شما...',contentPadding:EdgeInsets.symmetric(horizontal:12,vertical:10)))),
         const SizedBox(width:8),
         IconButton.filled(onPressed:_busy?null:_send,icon:_busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send_rounded),style:IconButton.styleFrom(backgroundColor:_brandRed,foregroundColor:Colors.white)),
       ]),
     ]),
   ),
 );
}


class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.action});
  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(title, style: const TextStyle(
        color: _ink, fontSize: 17, fontWeight: FontWeight.w800)),
      const Spacer(),
      if (action != null)
        Text(action!, style: const TextStyle(
          color: _brandRed, fontSize: 12, fontWeight: FontWeight.w700)),
    ],
  );
}

class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.service, required this.onRequest});
  final ServiceItem service;
  final Future<void> Function(ServiceItem service) onRequest;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: () => _showService(context, service, onRequest),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(service.icon, color: _brandRed, size: 27),
          Text(service.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink, fontWeight: FontWeight.w800, fontSize: 13)),
          Text(service.category, style: const TextStyle(
            color: _muted, fontSize: 10)),
        ],
      ),
    ),
  );
}

class ServiceListTile extends StatelessWidget {
  const ServiceListTile({super.key, required this.service, required this.onRequest});
  final ServiceItem service;
  final Future<void> Function(ServiceItem service) onRequest;

  @override
  Widget build(BuildContext context) => ListTile(
    tileColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    leading: CircleAvatar(
      backgroundColor: const Color(0xFFFCE8E8),
      child: Icon(service.icon, color: _brandRed),
    ),
    title: Text(service.title, style: const TextStyle(
      fontWeight: FontWeight.w800, color: _ink, fontSize: 14)),
    subtitle: Text(service.subtitle, style: const TextStyle(
      color: _muted, fontSize: 11, height: 1.7)),
    trailing: const Icon(Icons.chevron_left_rounded, color: _muted),
    onTap: () => _showService(context, service, onRequest),
  );
}

class StepTile extends StatelessWidget {
  const StepTile({super.key, required this.number,
    required this.title, required this.subtitle});
  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFFCE8E8),
          foregroundColor: _brandRed,
          child: Text(number, style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(
              color: _ink, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(
              color: _muted, fontSize: 11)),
          ],
        )),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon,
    required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Column(
      children: [
        Icon(icon, size: 44, color: const Color(0xFF94A3B8)),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(
          color: _ink, fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        Text(subtitle, textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, height: 1.8, fontSize: 12)),
      ],
    ),
  );
}

class ProfileOption extends StatelessWidget {
  const ProfileOption({super.key, required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    leading: Icon(icon, color: _navy),
    title: Text(title, style: const TextStyle(
      color: _ink, fontWeight: FontWeight.w600, fontSize: 13)),
    trailing: const Icon(Icons.chevron_left_rounded, color: _muted),
    onTap: () => _showInfo(context),
  );
}

class _ServiceMetaRow extends StatelessWidget {
  const _ServiceMetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        Icon(icon, size: 17, color: _brandRed),
        const SizedBox(width: 8),
        Expanded(child: Text(label,
            style: const TextStyle(color: _muted, fontSize: 12))),
        Text(value, style: const TextStyle(
            color: _ink, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

void _showService(BuildContext context,ServiceItem service,Future<void> Function(ServiceItem service) onRequest){
 showModalBottomSheet<void>(context:context,isScrollControlled:true,backgroundColor:Colors.white,shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(24))),builder:(sheet)=>Padding(padding:const EdgeInsets.fromLTRB(22,24,22,32),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
 Center(child:Container(width:42,height:4,decoration:BoxDecoration(color:const Color(0xFFCBD5E1),borderRadius:BorderRadius.circular(5)))),const SizedBox(height:22),Icon(service.icon,color:_brandRed,size:34),const SizedBox(height:14),
 Text(service.title,style:const TextStyle(color:_ink,fontWeight:FontWeight.w900,fontSize:20)),const SizedBox(height:8),Text(service.subtitle,style:const TextStyle(color:_muted,height:1.8)),
 if(service.estimatedDays!=null||service.basePrice!=null)...[const SizedBox(height:14),if(service.estimatedDays!=null)_ServiceMetaRow(icon:Icons.schedule_outlined,label:'زمان تخمینی انجام',value:'${service.estimatedDays} روز کاری'),if(service.basePrice!=null)_ServiceMetaRow(icon:Icons.payments_outlined,label:'مبلغ پایه ثبت‌شده (واحد نیازمند تأیید)',value:service.basePrice!.toString())],
 if(service.requirements.isNotEmpty)...[const SizedBox(height:16),const Text('مدارک و اطلاعات موردنیاز',style:TextStyle(color:_ink,fontWeight:FontWeight.w800)),const SizedBox(height:6),...service.requirements.map((item)=>Padding(padding:const EdgeInsets.only(bottom:5),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('•  ',style:TextStyle(color:_brandRed)),Expanded(child:Text(item,style:const TextStyle(color:_muted,height:1.6)))])))],
 const SizedBox(height:20),SizedBox(width:double.infinity,child:FilledButton(onPressed:(){Navigator.pop(sheet);onRequest(service);},child:const Text('درخواست این خدمت'))),const SizedBox(height:8),const Text('برای ثبت درخواست واقعی، ورود و اتصال امن به سامانه لازم است.',textAlign:TextAlign.center,style:TextStyle(color:_muted,fontSize:10)),
 ]))));
}

String errorText(Object? error) => error is KargozarApiException
    ? error.message
    : 'دریافت اطلاعات با مشکل روبه‌رو شد. نشانی سرور و اتصال اینترنت را بررسی کنید.';

void _showInfo(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('نسخه آزمایشی'),
      content: const Text(
        'این بخش در حال آماده‌سازی است. در نسخه عملیاتی، درخواست‌ها به سامانه کارگزار ارسال و قابل پیگیری خواهند بود.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('متوجه شدم'),
        ),
      ],
    ),
  );
}


class ServiceCategoryDetailPage extends StatelessWidget {
  const ServiceCategoryDetailPage({
    super.key,
    required this.category,
    required this.onBrowseServices,
  });

  final ServiceCategory category;
  final VoidCallback onBrowseServices;

  String get _intro {
    final name = category.name;
    switch (category.slug) {
      case 'business-licenses':
        return 'این بخش مسیر بررسی و پیگیری مجوزهای لازم برای شروع یا ادامه فعالیت اقتصادی را پوشش می‌دهد؛ از مجوز مشاغل خانگی و صنفی تا مجوزهای صنعتی و امور مرتبط با کارت بازرگانی. نوع مجوز بر اساس موضوع فعالیت، محل اجرا و شرایط متقاضی تعیین می‌شود.';
      case 'company-registration':
        return 'خدمات ثبتی شرکت‌ها و مؤسسات، از انتخاب قالب حقوقی و تأسیس تا ثبت تغییرات، شعب، انحلال و امور دفاتر قانونی را در بر می‌گیرد. مسیر مناسب بر اساس نوع شخصیت حقوقی و وضعیت پرونده مشخص می‌شود.';
      case 'trademark-intellectual-property':
        return 'این بخش برای ثبت و پیگیری حقوق مرتبط با نام و نشان تجاری، اختراع، طرح صنعتی و آثار فکری است. امکان ثبت و میزان حمایت، به ماهیت دارایی فکری و بررسی سوابق و شرایط قانونی وابسته است.';
      case 'supplementary-certificates':
        return 'مدارک و تأییدیه‌های مکمل موردنیاز برخی فعالیت‌ها، از جمله الزامات بهداشتی، استاندارد، تأییدیه‌های مرتبط با محل فعالیت و امور مالیاتی در این بخش قرار می‌گیرند. نوع مدرک بر اساس فعالیت و مرجع ذی‌صلاح تعیین می‌شود.';
      case 'banking-services':
        return 'این بخش خدمات مرتبط با امور بانکی کسب‌وکار را پوشش می‌دهد؛ از بررسی شرایط افتتاح حساب جاری و دریافت ابزار پذیرش تا پیگیری درخواست تسهیلات. تصمیم نهایی درباره افتتاح حساب یا اعطای تسهیلات با بانک و بر اساس ضوابط آن است.';
      case 'legal-contract-services':
        return 'خدمات تنظیم و بررسی قراردادها و اسناد موردنیاز روابط کاری، پیمانکاری، تجاری و مشارکتی در این بخش ارائه می‌شود. متن هر سند باید متناسب با موضوع، تعهدات طرفین و شرایط واقعی توافق تهیه و بررسی شود.';
      case 'internet-commerce-services':
        return 'این بخش به راه‌اندازی و توسعه حضور آنلاین کسب‌وکار اختصاص دارد؛ از وب‌سایت، دامنه و میزبانی تا تلفن اینترنتی، پیامک، تجارت الکترونیک و اپلیکیشن. دامنه کار بر اساس نیاز و زیرساخت موردنظر تعیین می‌شود.';
      case 'real-estate-contracts':
        return 'خدمات تنظیم، تمدید، اصلاح و بررسی قراردادهای ملکی در این بخش قرار می‌گیرند. نوع قرارداد، مشخصات ملک و طرفین، وضعیت مالکیت و الزامات ثبت و رهگیری پیش از تنظیم سند بررسی می‌شود.';
      case 'business-development':
        return 'این بخش ابزارها و نرم‌افزارهای مدیریتی برای اداره منظم‌تر کسب‌وکار را معرفی می‌کند؛ از حسابداری و فروش تا مدیریت پرسنل، قراردادها، مشتریان، انبار و گزارش‌گیری.';
      case 'specialized-services':
        return 'در این بخش درخواست‌های تخصصی و پروژه‌ای قرار می‌گیرند که در دسته‌های اصلی دیگر جای نمی‌گیرند؛ مانند مطالعات امکان‌سنجی، تدوین طرح کسب‌وکار، ارزش‌گذاری و خدمات تخصصی تجارت خارجی یا جذب سرمایه.';
    }
    if (category.slug.startsWith('guild-')) {
      return 'این بخش برای متقاضیان دریافت جواز کسب صنفی در گروه «$name» طراحی شده است. نوع فعالیت، محل کسب و شرایط اختصاصی رسته پس از بررسی اولیه مشخص می‌شود.';
    }
    if (category.slug == 'home-business-license') {
      return 'این خدمت برای بررسی شرایط و پیگیری مجوز فعالیت‌های واجد شرایط در محیط مسکونی ارائه می‌شود. امکان صدور و شرایط دقیق، به نوع فعالیت و ضوابط مرجع صادرکننده بستگی دارد.';
    }
    if (category.slug == 'institutional-business-license') {
      return 'این خدمت مربوط به بررسی و پیگیری مجوز فعالیت‌های صنعتی است. نوع مجوز و مرجع ذی‌صلاح بر اساس ماهیت فعالیت، ظرفیت، محل استقرار و الزامات قانونی تعیین می‌شود.';
    }
    if (category.slug.startsWith('commercial-card') || category.slug == 'chamber-membership') {
      return 'این خدمت برای بررسی شرایط و پیگیری امور مرتبط با کارت بازرگانی یا عضویت اتاق بازرگانی ارائه می‌شود. مدارک و شرایط اشخاص حقیقی و حقوقی متفاوت است.';
    }
    if (category.slug.startsWith('company-') || category.slug.contains('company') || category.slug.contains('branch') || category.slug == 'legal-books' || category.slug == 'non-commercial-institutions') {
      return 'کارگزار مراحل اداری و ثبتی مربوط به «$name» را بررسی و پیگیری می‌کند. نوع شخصیت حقوقی، آخرین وضعیت ثبتی و مدارک پرونده در تعیین مسیر انجام کار مؤثر است.';
    }
    if (category.slug.contains('trademark') || category.slug.contains('industrial-design') || category.slug.contains('patent') || category.slug.contains('copyright') || category.slug.contains('-ip')) {
      return 'این خدمت در حوزه ثبت و حمایت از دارایی‌های فکری ارائه می‌شود. امکان ثبت، مدارک و مراحل رسیدگی با توجه به ماهیت اثر، علامت یا اختراع و سوابق مشابه بررسی می‌شود.';
    }
    if (category.slug.contains('health') || category.slug.contains('standard') || category.slug.contains('certificate') || category.slug.contains('tax') || category.slug.contains('police') || category.slug.contains('sib-salamat') || category.slug.contains('trade-rulings')) {
      return 'این خدمت برای بررسی الزامات و پیگیری دریافت مدرک یا تأییدیه «$name» ارائه می‌شود. شرایط دقیق بر اساس نوع فعالیت، محل و ضوابط مرجع مربوط تعیین خواهد شد.';
    }
    return 'کارگزار درخواست «$name» را بررسی می‌کند، مدارک و مسیر انجام را به شما اعلام می‌کند و پیگیری مراحل اداری را تا حصول نتیجه بر عهده می‌گیرد.';
  }

  List<String> get _examples {
    if (category.children.isNotEmpty) {
      return category.children.map((child) => child.name).toList(growable: false);
    }
    if (category.slug == 'guild-production') return const ['تولید پوشاک و منسوجات', 'تولید محصولات غذایی و خوراکی', 'تولید مصنوعات چوبی و فلزی', 'تولید محصولات هنری', 'صنایع‌دستی', 'تولید محصولات چرمی', 'تولید محصولات پلاستیکی', 'تولید لوازم و تجهیزات', 'تولید محصولات تزئینی', 'سایر فعالیت‌های تولیدی مجاز'];
    if (category.slug == 'guild-technical-services') return const ['تعمیر لوازم خانگی', 'تعمیر تجهیزات الکترونیکی', 'خدمات برق‌کاری', 'تأسیسات ساختمان', 'تعمیر خودرو', 'تعمیر موتورسیکلت', 'خدمات رایانه و شبکه', 'تعمیر تجهیزات صنعتی', 'خدمات فنی ساختمان', 'سایر خدمات فنی مجاز'];
    if (category.slug == 'guild-distribution-retail') return const ['فروشگاه پوشاک', 'فروشگاه مواد غذایی', 'فروشگاه لوازم خانگی', 'فروشگاه لوازم آرایشی و بهداشتی', 'فروشگاه ابزار و یراق', 'فروشگاه لوازم الکترونیکی', 'فروشگاه محصولات فرهنگی', 'عمده‌فروشی کالا', 'خرده‌فروشی کالا', 'سایر فعالیت‌های توزیعی مجاز'];
    if (category.slug == 'guild-services') return const ['خدمات آموزشی', 'خدمات نظافتی', 'خدمات آرایشی و پیرایشی', 'خدمات پذیرایی', 'خدمات رایانه‌ای', 'خدمات تبلیغاتی', 'خدمات طراحی', 'خدمات مشاوره‌ای', 'خدمات نگهداری', 'سایر فعالیت‌های خدماتی مجاز'];
    if (category.slug == 'company-incorporation') return const ['شرکت با مسئولیت محدود', 'شرکت سهامی خاص', 'شرکت سهامی عام', 'شرکت تضامنی', 'شرکت نسبی', 'شرکت مختلط سهامی', 'شرکت مختلط غیرسهامی', 'شرکت تعاونی'];
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('معرفی خدمت')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F3F8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8DDE9)),
            ),
            child: Column(
              children: [
                if (serviceCategoryImages[category.slug] != null) ...[
                  AppContentImage(
                    fileName: serviceCategoryImages[category.slug]!,
                    height: 118,
                    width: double.infinity,
                    fallbackIcon: Icons.assignment_turned_in_outlined,
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  const Icon(Icons.assignment_turned_in_outlined, color: _navy, size: 42),
                  const SizedBox(height: 12),
                ],
                Text(category.name, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _ink)),
                const SizedBox(height: 10),
                const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.devices_outlined, size: 17, color: Color(0xFF16834A)),
                  SizedBox(width: 6),
                  Text('پیگیری غیرحضوری توسط کارگزار',
                    style: TextStyle(color: Color(0xFF16834A), fontSize: 12, fontWeight: FontWeight.w800)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _detailHeading('درباره این خدمت'),
          Text(_intro, style: const TextStyle(color: _muted, height: 1.9, fontSize: 13)),
          if (_examples.isNotEmpty) ...[
            const SizedBox(height: 18),
            _detailHeading('نمونه فعالیت‌های مرتبط'),
            const Text('نمونه‌های زیر برای آشنایی هستند و عنوان رسمی رسته یا مجوز محسوب نمی‌شوند:',
              style: TextStyle(color: _muted, fontSize: 11, height: 1.7)),
            const SizedBox(height: 7),
            ..._examples.map((item) => _detailBullet(item)),
          ],
          const SizedBox(height: 18),
          _detailHeading('نحوه انجام غیرحضوری'),
          _detailBullet('ثبت درخواست و ارسال اطلاعات اولیه به‌صورت آنلاین'),
          _detailBullet('بررسی شرایط و اعلام مدارک متناسب با پرونده'),
          _detailBullet('تکمیل پرونده و پیگیری مراحل اداری توسط کارگزار'),
          _detailBullet('اطلاع‌رسانی وضعیت و نتیجه پیگیری به متقاضی'),
          const SizedBox(height: 18),
          _detailHeading('مدارک و اطلاعات موردنیاز'),
          const Text('فهرست دقیق مدارک پس از بررسی نوع خدمت، مشخصات متقاضی و ضوابط مرجع مربوط اعلام می‌شود. کارگزار در آماده‌سازی، تکمیل و پیگیری مدارک قابل ارائه کمک می‌کند؛ مواردی که ارائه یا تأیید آن‌ها فقط از سوی متقاضی ممکن باشد، از ابتدا شفاف اعلام خواهد شد.',
            style: TextStyle(color: _muted, height: 1.9, fontSize: 13)),
          const SizedBox(height: 18),
          _detailHeading('مدت زمان انجام'),
          const Text('مدت زمان پس از بررسی پرونده و مشخص شدن مسیر قانونی اعلام می‌شود و به کامل بودن مدارک، استعلام‌ها و زمان پاسخ مرجع صادرکننده بستگی دارد. از اعلام زمان قطعی پیش از بررسی پرونده خودداری می‌شود.',
            style: TextStyle(color: _muted, height: 1.9, fontSize: 13)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F8F3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD6EBDD)),
            ),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.home_work_outlined, color: Color(0xFF16834A), size: 22),
              SizedBox(width: 10),
              Expanded(child: Text('بدون مراجعه به دفتر کارگزار؛ دریافت اطلاعات، هماهنگی و پیگیری پرونده به‌صورت غیرحضوری انجام می‌شود. در صورت وجود الزام قانونی برای اقدام شخص متقاضی، پیش از شروع کار اطلاع داده خواهد شد.',
                style: TextStyle(color: _ink, fontSize: 12, height: 1.8))),
            ]),
          ),
          const SizedBox(height: 22),
          SizedBox(width: double.infinity, child: FilledButton(
            onPressed: onBrowseServices,
            child: const Text('ثبت درخواست / مشاهده خدمات این بخش'),
          )),
          const SizedBox(height: 8),
          const Text('ثبت نهایی درخواست زمانی انجام می‌شود که خدمت به کاتالوگ و سامانه درخواست متصل باشد.',
            textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 10, height: 1.6)),
        ],
      ),
    );
  }
}

Widget _detailHeading(String title) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(title, style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w900)),
);

Widget _detailBullet(String value) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('•  ', style: TextStyle(color: _brandRed, fontWeight: FontWeight.w900)),
    Expanded(child: Text(value, style: const TextStyle(color: _muted, fontSize: 12, height: 1.7))),
  ]),
);

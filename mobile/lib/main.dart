import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'features/content/service_descriptions.dart';
import 'features/content/legal_pages.dart';
import 'core/network/kargozar_api_client.dart';
import 'features/auth/customer_session.dart';
import 'features/catalog/service_catalog_repository.dart';
import 'features/requests/customer_request_repository.dart';
import 'features/catalog/service_taxonomy.dart';
import 'features/content/app_content.dart';

void main() {
  runApp(const KargozarApp());
}

const _navy = Color(0xFF49334F); // برند مکمل: بادمجانی تیره
const _teal = Color(0xFFC62828); // رنگ اصلی برند: قرمز
const _ink = Color(0xFF1E293B);
const _muted = Color(0xFF64748B);
const _canvas = Color(0xFFFFFFFF);

class KargozarApp extends StatefulWidget {
 const KargozarApp({super.key,this.apiClient}); final KargozarApiClient? apiClient;
 @override State<KargozarApp> createState()=>_KargozarAppState();
}
class _KargozarAppState extends State<KargozarApp>{
 late final KargozarApiClient _api; late final CustomerSession _session; late final CustomerRequestRepository _requests;
 bool _loading=false,_signedIn=false;
 @override void initState(){super.initState();_api=widget.apiClient??KargozarApiClient();_session=CustomerSession(_api);_requests=CustomerRequestRepository(_api);}
 final _navigatorKey=GlobalKey<NavigatorState>();
 Future<bool> _login()async{final dialogContext=_navigatorKey.currentContext;if(dialogContext==null)return false;final ok=await showDialog<bool>(context:dialogContext,barrierDismissible:false,builder:(_)=>OtpDialog(session:_session));final authenticated=ok==true&&_session.isAuthenticated;if(mounted)setState(()=>_signedIn=authenticated);return authenticated;}
 Future<void> _logout()async{try{await _session.signOut();}catch(_){}if(mounted)setState(()=>_signedIn=false);}
 @override void dispose(){_api.close();super.dispose();}
 @override Widget build(BuildContext context)=>MaterialApp(
 navigatorKey:_navigatorKey,
 debugShowCheckedModeBanner:false,title:'کارگزار',
 theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:_canvas,colorScheme:ColorScheme.fromSeed(seedColor:_teal,primary:_teal,secondary:_navy,surface:Colors.white),fontFamily:'Roboto',
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
    final uri = Uri(scheme: 'tel', path: '09365952800');
    final opened = await launchUrl(uri);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('امکان باز کردن شماره‌گیر وجود ندارد.')),
      );
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
  Future<void> _openCategory(ServiceCategory category) async {
    if (category.children.isNotEmpty) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (sheetContext) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * .68,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _ink)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: category.children.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final child = category.children[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                          title: Text(child.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_left_rounded, color: _muted),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _openCategory(child);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return;
    }

    final description = serviceDescriptions[category.slug] ??
        'برای دریافت اطلاعات درباره این خدمت، شرایط و مدارک موردنیاز و بررسی مسیر مناسب، با کارشناسان کارگزار تماس بگیرید.';
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: Text(category.name)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
              children: [
                const Icon(Icons.description_outlined, color: _teal, size: 38),
                const SizedBox(height: 18),
                Text(category.name, style: const TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 20)),
                const SizedBox(height: 14),
                Text(description, style: const TextStyle(color: _muted, height: 2, fontSize: 14)),
                const SizedBox(height: 24),
                const Text('برای دریافت مشاوره و پیگیری این خدمت با کارگزار تماس بگیرید.', style: TextStyle(color: _ink, height: 1.8, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final opened = await launchUrl(Uri(scheme: 'tel', path: '09365952800'));
                      if (!opened && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('امکان باز کردن شماره‌گیر وجود ندارد.')));
                      }
                    },
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('تماس با کارگزار'),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(child: Text('۰۹۳۶۵۹۵۲۸۰۰', style: TextStyle(color: _muted, fontSize: 13))),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  void _showConsultation() {
    launchUrl(Uri(scheme: 'tel', path: '09365952800'));
  }
  void _openCompanion(int index) {
    final item = companionModules[index];
    final description = companionDescriptions.length > index
        ? companionDescriptions[index]
        : item.subtitle;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: Text(item.title)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
              children: [
                Icon(item.icon, color: _teal, size: 38),
                const SizedBox(height: 18),
                Text(item.title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 20)),
                const SizedBox(height: 14),
                Text(description, style: const TextStyle(color: _muted, height: 2, fontSize: 14)),
                const SizedBox(height: 24),
                const Text('برای دریافت اطلاعات و مشاوره با کارگزار تماس بگیرید.', style: TextStyle(color: _ink, height: 1.8, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => launchUrl(Uri(scheme: 'tel', path: '09365952800')),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('تماس با کارگزار'),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(child: Text('۰۹۳۶۵۹۵۲۸۰۰', style: TextStyle(color: _muted, fontSize: 13))),
              ],
            ),
          ),
        ),
      ),
    ));
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
          ServicesPage(onRequest: _request, onOpenCategory: _openCategory, onNavigate: (tab) { if (tab == 4) { _goToTab(2); _openCompanion(0); } else { _goToTab(tab); } }, onConsultation: _showConsultation),
          CompanionContentPage(onOpen: _openCompanion, onNavigate: (tab) { if (tab == 4) { _goToTab(2); _openCompanion(0); } else { _goToTab(tab); } }, onConsultation: _showConsultation),
          SupportContentPage(onConsultation: _showConsultation, onNavigate: _goToTab),
        ],
      ),
      Positioned(right: 14, bottom: 8, child: SupportChatLauncher(api: widget.api, signedIn: widget.signedIn, onLogin: widget.onLogin)),
    ])),
    bottomNavigationBar: NavigationBar(
      height: 44,
      backgroundColor: _teal,
      indicatorColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w600),
      ),
      selectedIndex: _index,
      onDestinationSelected: _goToTab,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.person_outline_rounded, color: Colors.white, size: 16), selectedIcon: Icon(Icons.person_rounded, color: Colors.white, size: 16), label: 'حساب کاربری من'),
        NavigationDestination(icon: Icon(Icons.grid_view_outlined, color: Colors.white, size: 16), selectedIcon: Icon(Icons.grid_view_rounded, color: Colors.white, size: 16), label: 'خدمات'),
        NavigationDestination(icon: Icon(Icons.business_center_outlined, color: Colors.white, size: 16), selectedIcon: Icon(Icons.business_center_rounded, color: Colors.white, size: 16), label: 'همراه کسب‌وکار'),
        NavigationDestination(icon: Icon(Icons.support_agent_outlined, color: Colors.white, size: 16), selectedIcon: Icon(Icons.support_agent_rounded, color: Colors.white, size: 16), label: 'تماس و پشتیبانی'),
      ],
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
  const ServicesPage({super.key, required this.onRequest, required this.onOpenCategory, required this.onNavigate, required this.onConsultation});
  final Future<void> Function(ServiceItem service) onRequest;
  final ValueChanged<ServiceCategory> onOpenCategory;
  final ValueChanged<int> onNavigate;
  final VoidCallback onConsultation;

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final searchableServices = <MapEntry<String, ServiceCategory>>[];
    for (final parent in serviceTaxonomy) {
      final leaves = parent.children.isEmpty
          ? <ServiceCategory>[parent]
          : parent.children;
      for (final leaf in leaves) {
        searchableServices.add(MapEntry(parent.name, leaf));
      }
    }

    final matchingServices = searchableServices.where((entry) {
      if (normalizedQuery.isEmpty) return true;
      final description = serviceDescriptions[entry.value.slug] ?? '';
      return entry.value.name.toLowerCase().contains(normalizedQuery) ||
          entry.key.toLowerCase().contains(normalizedQuery) ||
          description.toLowerCase().contains(normalizedQuery);
    }).toList();
    final visibleServices = normalizedQuery.isEmpty
        ? matchingServices.take(4).toList()
        : matchingServices;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        AppBannerStrip(
          onNavigate: widget.onNavigate,
          onConsultation: widget.onConsultation,
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 2, 14, 10),
          child: Text(
            'دسته‌بندی خدمات',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _navy),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: serviceTaxonomy.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              final category = serviceTaxonomy[index];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => widget.onOpenCategory(category),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppContentImage(
                        fileName: serviceCategoryImages[category.slug] ?? 'missing.png',
                        fallbackIcon: Icons.category_outlined,
                        borderRadius: 0,
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(8, 20, 8, 11),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xD9000000)],
                            ),
                          ),
                          child: Text(
                            category.name,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              height: 1.35,
                              fontWeight: FontWeight.w900,
                              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                            ),
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
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            textDirection: TextDirection.rtl,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'جست‌وجوی خدمات...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Text(
            normalizedQuery.isEmpty ? 'خدمات منتخب' : 'نتایج جست‌وجو',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _navy),
          ),
        ),
        if (visibleServices.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Text('خدمتی با این عبارت پیدا نشد.', textAlign: TextAlign.center),
          )
        else
          ...visibleServices.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => widget.onOpenCategory(entry.value),
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined, color: _teal),
                    title: Text(entry.value.name, style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: Text(entry.key, style: const TextStyle(color: _muted, fontSize: 11)),
                    trailing: const Icon(Icons.chevron_left_rounded, color: _muted),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
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
void _showRequestDetails(BuildContext context,CustomerServiceRequest request){showModalBottomSheet<void>(context:context,isScrollControlled:true,backgroundColor:Colors.white,shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(24))),builder:(ctx)=>SafeArea(child:Padding(padding:const EdgeInsets.all(20),child:ListView(shrinkWrap:true,children:[Text('پیگیری ${request.trackingCode}',style:const TextStyle(fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:10),Text('وضعیت فعلی: ${requestStatusLabel(request.status)}'),if(request.customerNote?.isNotEmpty==true)Text('توضیحات: ${request.customerNote}'),const SizedBox(height:18),const Text('آخرین رویدادها',style:TextStyle(fontWeight:FontWeight.w800)),if(request.events.isEmpty)const Text('هنوز رویدادی برای این درخواست ثبت نشده است.'),...request.events.map((e)=>ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.timeline_rounded,color:_teal),title:Text(e.publicMessage??requestStatusLabel(e.status)),subtitle:Text(requestStatusLabel(e.status))))]))));}
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
   Padding(
     padding: const EdgeInsets.symmetric(horizontal: 16),
     child: Column(
       crossAxisAlignment: CrossAxisAlignment.stretch,
       children: [
         const Text('به کارگزار خوش آمدید', style: TextStyle(color:_ink,fontSize:18,fontWeight:FontWeight.w900)),
         const SizedBox(height:8),
         const Text('کارگزار، راهنمای شما برای دریافت خدمات اداری، ثبتی و توسعه کسب‌وکار است. برای مشاهده خدمات نیازی به ورود یا ثبت‌نام ندارید.', style: TextStyle(color:_muted,height:1.8,fontSize:13)),
         const SizedBox(height:18),
         _ProfileAction(icon:Icons.grid_view_rounded,title:'مشاهده خدمات کارگزار',onTap:()=>onNavigate(1)),
         const SizedBox(height:7),
         _ProfileAction(icon:Icons.support_agent_outlined,title:'تماس و پشتیبانی',onTap:()=>onNavigate(3)),
         const SizedBox(height:7),
         _ProfileAction(icon:Icons.call_outlined,title:'تماس مستقیم با کارگزار',onTap:()=>launchUrl(Uri(scheme:'tel',path:'09365952800'))),
         const SizedBox(height:7),
         _ProfileAction(
           icon:Icons.info_outline_rounded,
           title:'درباره کارگزار',
           onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>const KargozarAboutPage())),
         ),
         const SizedBox(height:7),
         _ProfileAction(
           icon:Icons.policy_outlined,
           title:'قوانین و شرایط استفاده',
           onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>const KargozarTermsPage())),
         ),
         const SizedBox(height:7),
         _ProfileAction(
           icon:Icons.privacy_tip_outlined,
           title:'سیاست حفظ حریم خصوصی',
           onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>const KargozarPrivacyPage())),
         ),
       ],
     ),
   ),
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
       child:Row(children:[Icon(icon,color:_teal,size:22),const SizedBox(width:12),Expanded(child:Text(title,style:const TextStyle(color:_ink,fontSize:13,fontWeight:FontWeight.w700))),const Icon(Icons.chevron_left_rounded,color:_muted,size:20)]),
     ),
   ),
 );
}

class SupportChatLauncher extends StatelessWidget {
 const SupportChatLauncher({super.key,required this.api,required this.signedIn,required this.onLogin});
 final KargozarApiClient api; final bool signedIn; final Future<bool> Function() onLogin;
 @override
 Widget build(BuildContext context)=>Material(
   color:_teal,
   shape:const CircleBorder(),
   elevation:4,
   child:InkWell(
     onTap:()=>launchUrl(Uri(scheme:'tel',path:'09365952800')),
     customBorder:const CircleBorder(),
     child:const SizedBox(width:44,height:44,child:Icon(Icons.call_rounded,color:Colors.white,size:21)),
   ),
 );
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
       ? await widget.api.startSupportConversation(body)
       : await widget.api.sendSupportMessage(_conversationId!,body);
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
     final response=await widget.api.getSupportMessages(id);
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
       const Row(children:[Icon(Icons.support_agent,color:_teal),SizedBox(width:8),Text('پشتیبانی آنلاین کارگزار',style:TextStyle(fontSize:16,fontWeight:FontWeight.w800)),Spacer(),Text('گفت‌وگو',style:TextStyle(fontSize:11,color:_muted))]),
       const Divider(height:22),
       Expanded(child:_messages.isEmpty?const Center(child:Text('پیام خود را بنویسید تا گفت‌وگو با کارشناس آغاز شود.',textAlign:TextAlign.center,style:TextStyle(color:_muted,height:1.8))):ListView.builder(controller:_scroll,itemCount:_messages.length,itemBuilder:(context,index){
         final message=_messages[index];final mine=message['sender_type']=='customer';
         return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:Container(
           constraints:BoxConstraints(maxWidth:MediaQuery.sizeOf(context).width*.76),
           margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.symmetric(horizontal:12,vertical:9),
           decoration:BoxDecoration(color:mine?const Color(0xFFFCE8E8):const Color(0xFFF1F5F9),borderRadius:BorderRadius.circular(13)),
           child:Text(message['body']?.toString()??'',style:const TextStyle(fontSize:12,height:1.6)),
         ));
       })),
       if(_error!=null)Padding(padding:const EdgeInsets.only(bottom:8),child:Text(_error!,style:const TextStyle(color:Colors.red,fontSize:11))),
       Row(children:[
         Expanded(child:TextField(controller:_controller,minLines:1,maxLines:3,textInputAction:TextInputAction.send,onSubmitted:(_)=>_send(),decoration:const InputDecoration(hintText:'پیام شما...',contentPadding:EdgeInsets.symmetric(horizontal:12,vertical:10)))),
         const SizedBox(width:8),
         IconButton.filled(onPressed:_busy?null:_send,icon:_busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send_rounded),style:IconButton.styleFrom(backgroundColor:_teal,foregroundColor:Colors.white)),
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
          color: _teal, fontSize: 12, fontWeight: FontWeight.w700)),
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
          Icon(service.icon, color: _teal, size: 27),
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
      child: Icon(service.icon, color: _teal),
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
          foregroundColor: _teal,
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

void _showService(BuildContext context,ServiceItem service,Future<void> Function(ServiceItem service) onRequest){
 showModalBottomSheet<void>(
   context:context,isScrollControlled:true,backgroundColor:Colors.white,
   shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(24))),
   builder:(sheet)=>Padding(
     padding:const EdgeInsets.fromLTRB(22,24,22,32),
     child:SingleChildScrollView(child:Column(
       mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,
       children:[
         Center(child:Container(width:42,height:4,decoration:BoxDecoration(color:const Color(0xFFCBD5E1),borderRadius:BorderRadius.circular(5)))),
         const SizedBox(height:22),
         Icon(service.icon,color:_teal,size:34),
         const SizedBox(height:14),
         Text(service.title,style:const TextStyle(color:_ink,fontWeight:FontWeight.w900,fontSize:20)),
         const SizedBox(height:8),
         Text(service.subtitle,style:const TextStyle(color:_muted,height:1.8)),
         const SizedBox(height:20),
         SizedBox(width:double.infinity,child:FilledButton.icon(
           onPressed:(){Navigator.pop(sheet);onRequest(service);},
           icon:const Icon(Icons.call_outlined),
           label:const Text('تماس برای دریافت خدمت'),
         )),
         const SizedBox(height:8),
         const Center(child:Text('۰۹۳۶۵۹۵۲۸۰۰',style:TextStyle(color:_muted,fontSize:12))),
       ],
     )),
   ),
 );
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

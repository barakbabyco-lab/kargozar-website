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
 theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:_canvas,colorScheme:ColorScheme.fromSeed(seedColor:_teal,primary:_teal,secondary:_navy,surface:Colors.white),fontFamily:'Roboto',
 appBarTheme:const AppBarTheme(backgroundColor:_canvas,foregroundColor:_ink,centerTitle:false,elevation:0),
 inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:Color(0xFFE2E8F0))),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:Color(0xFFE2E8F0))))),
 home:Directionality(textDirection:TextDirection.rtl,child:_loading?const Scaffold(body:Center(child:CircularProgressIndicator())):MainShell(requests:_requests,signedIn:_signedIn,onLogin:_login,onLogout:_logout)),
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
  const MainShell({super.key, required this.requests, required this.signedIn, required this.onLogin, required this.onLogout});
  final CustomerRequestRepository requests;
  final bool signedIn;
  final Future<bool> Function() onLogin;
  final VoidCallback onLogout;
  @override State<MainShell> createState() => _MainShellState();
}
class _MainShellState extends State<MainShell> {
  int _index = 1, _revision = 0;
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
  void _showConsultation() {
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('مشاوره رایگان کارگزار'),
      content: const Text('فرم ثبت درخواست مشاوره باید به سرویس ارتباط با کارشناسان متصل شود. تا زمان اتصال، این بخش درخواست ساختگی ثبت نمی‌کند.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('متوجه شدم'))],
    ));
  }
  void _openCompanion(int index) {
    final item = companionModules[index];
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: Text(item.title),
      content: Text('${item.subtitle}\n\nصفحه عملیاتی این ماژول در مرحله تکمیل و اتصال به سامانه است.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بستن'))],
    ));
  }
  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: IndexedStack(index: _index, children: [
      ProfilePage(signedIn: widget.signedIn, onLogin: widget.onLogin, onLogout: widget.onLogout, onShowRequests: _showRequests),
      ServicesPage(onRequest: _request, onNavigate: (tab) { if (tab == 4) { setState(() => _index = 2); _openCompanion(0); } else { setState(() => _index = tab); } }, onConsultation: _showConsultation),
      CompanionContentPage(
        onOpen: _openCompanion,
        onNavigate: (tab) {
          if (tab == 4) {
            setState(() => _index = 2);
            _openCompanion(0);
          } else {
            setState(() => _index = tab);
          }
        },
        onConsultation: _showConsultation,
      ),
      SupportContentPage(onConsultation: _showConsultation),
    ])),
    bottomNavigationBar: NavigationBar(
      height: 40,
      backgroundColor: _teal,
      indicatorColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600),
      ),
      selectedIndex: _index,
      onDestinationSelected: (value) => setState(() => _index = value),
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
  const ServicesPage({super.key, required this.onRequest, required this.onNavigate, required this.onConsultation});
  final Future<void> Function(ServiceItem service) onRequest;
  final ValueChanged<int> onNavigate;
  final VoidCallback onConsultation;

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  late final KargozarApiClient _api;
  late final ServiceCatalogRepository _catalog;
  bool _apiConfigured = false;

  @override
  void initState() {
    super.initState();
    _api = KargozarApiClient();
    _catalog = ServiceCatalogRepository(_api);
    _apiConfigured = const String.fromEnvironment('API_BASE_URL').trim().isNotEmpty;
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        AppBannerStrip(
          onNavigate: widget.onNavigate,
          onConsultation: widget.onConsultation,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: serviceTaxonomy.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 11,
              mainAxisSpacing: 11,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final category = serviceTaxonomy[index];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {},
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: AppContentImage(
                          fileName: serviceCategoryImages[category.slug] ??
                              'missing.png',
                          fallbackIcon: Icons.category_outlined,
                          borderRadius: 0,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(9),
                        child: Text(
                          category.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _ink,
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
        const SizedBox(height: 20),
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
 const ProfilePage({super.key,required this.signedIn,required this.onLogin,required this.onLogout,required this.onShowRequests});final bool signedIn;final VoidCallback onLogin,onLogout,onShowRequests;
 @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(20),children:[
 const Text('حساب کاربری',style:TextStyle(color:_ink,fontSize:25,fontWeight:FontWeight.w900)),const SizedBox(height:18),
 Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:Row(children:[const CircleAvatar(radius:26,backgroundColor:Color(0xFFE8EEF5),child:Icon(Icons.person_outline,color:_navy,size:28)),const SizedBox(width:13),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(signedIn?'حساب شما فعال است':'مهمان',style:const TextStyle(color:_ink,fontWeight:FontWeight.bold,fontSize:16)),Text(signedIn?'به حساب کاربری خود وارد شده‌اید':'برای استفاده از خدمات وارد شوید',style:const TextStyle(color:_muted,fontSize:12))])])),const SizedBox(height:14),
 ListTile(leading:const Icon(Icons.receipt_long_outlined,color:_navy),title:const Text('درخواست‌های من'),trailing:const Icon(Icons.chevron_left_rounded,color:_muted),onTap:onShowRequests),
 ListTile(leading:Icon(signedIn?Icons.logout:Icons.login,color:_navy),title:Text(signedIn?'خروج از حساب':'ورود / ثبت‌نام'),trailing:const Icon(Icons.chevron_left_rounded,color:_muted),onTap:signedIn?onLogout:onLogin),
 const ProfileOption(icon:Icons.support_agent,title:'پشتیبانی و تماس با ما'),const ProfileOption(icon:Icons.policy_outlined,title:'قوانین و حریم خصوصی'),const ProfileOption(icon:Icons.info_outline,title:'درباره کارگزار'),
 ]);
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
        Icon(icon, size: 17, color: _teal),
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
 Center(child:Container(width:42,height:4,decoration:BoxDecoration(color:const Color(0xFFCBD5E1),borderRadius:BorderRadius.circular(5)))),const SizedBox(height:22),Icon(service.icon,color:_teal,size:34),const SizedBox(height:14),
 Text(service.title,style:const TextStyle(color:_ink,fontWeight:FontWeight.w900,fontSize:20)),const SizedBox(height:8),Text(service.subtitle,style:const TextStyle(color:_muted,height:1.8)),
 if(service.estimatedDays!=null||service.basePrice!=null)...[const SizedBox(height:14),if(service.estimatedDays!=null)_ServiceMetaRow(icon:Icons.schedule_outlined,label:'زمان تخمینی انجام',value:'${service.estimatedDays} روز کاری'),if(service.basePrice!=null)_ServiceMetaRow(icon:Icons.payments_outlined,label:'مبلغ پایه ثبت‌شده (واحد نیازمند تأیید)',value:service.basePrice!.toString())],
 if(service.requirements.isNotEmpty)...[const SizedBox(height:16),const Text('مدارک و اطلاعات موردنیاز',style:TextStyle(color:_ink,fontWeight:FontWeight.w800)),const SizedBox(height:6),...service.requirements.map((item)=>Padding(padding:const EdgeInsets.only(bottom:5),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('•  ',style:TextStyle(color:_teal)),Expanded(child:Text(item,style:const TextStyle(color:_muted,height:1.6)))])))],
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

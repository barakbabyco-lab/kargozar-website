import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kargozar_mobile/core/network/kargozar_api_client.dart';
import 'package:kargozar_mobile/features/auth/customer_session.dart';
import 'package:kargozar_mobile/features/catalog/service_catalog_repository.dart';
import 'package:kargozar_mobile/features/requests/customer_request_repository.dart';

const navy = Color(0xFF142B4A), teal = Color(0xFF168C83), muted = Color(0xFF64748B);
class KargozarApp extends StatefulWidget {
  const KargozarApp({super.key});
  @override State<KargozarApp> createState() => _AppState();
}
class _AppState extends State<KargozarApp> {
  late final api = KargozarApiClient();
  late final session = CustomerSession(api);
  late final catalog = ServiceCatalogRepository(api);
  late final requests = CustomerRequestRepository(api);
  bool loading = true, signedIn = false;
  @override void initState() { super.initState(); session.restore().then((v) { if (mounted) setState(() { signedIn = v; loading = false; }); }).catchError((_) { if (mounted) setState(() => loading = false); }); }
  @override void dispose() { api.close(); super.dispose(); }
  Future<void> login() async { final ok = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => OtpDialog(session: session)); if (ok == true && mounted) setState(() => signedIn = true); }
  Future<void> logout() async { try { await session.signOut(); } catch (_) {} if (mounted) setState(() => signedIn = false); }
  @override Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, title: 'کارگزار',
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF5F7FA), colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy, secondary: teal)),
    home: Directionality(textDirection: TextDirection.rtl, child: loading ? const Scaffold(body: Center(child: CircularProgressIndicator())) :
      MainShell(catalog: catalog, requests: requests, signedIn: signedIn, onLogin: login, onLogout: logout)));
}
class OtpDialog extends StatefulWidget {
  const OtpDialog({super.key, required this.session}); final CustomerSession session;
  @override State<OtpDialog> createState() => _OtpState();
}
class _OtpState extends State<OtpDialog> {
  final mobile = TextEditingController(), code = TextEditingController();
  bool requested = false, busy = false; String? error;
  @override void dispose() { mobile.dispose(); code.dispose(); super.dispose(); }
  Future<void> submit() async {
    if (!RegExp(r'^09\d{9}$').hasMatch(mobile.text.trim())) { setState(() => error = 'شماره موبایل معتبر وارد کن.'); return; }
    if (requested && !RegExp(r'^\d{4,8}$').hasMatch(code.text.trim())) { setState(() => error = 'کد ورود معتبر نیست.'); return; }
    setState(() { busy = true; error = null; });
    try { if (!requested) { await widget.session.requestOtp(mobile.text.trim()); if (mounted) setState(() => requested = true); }
      else { await widget.session.verifyOtp(mobile: mobile.text.trim(), code: code.text.trim()); if (mounted) Navigator.pop(context, true); } }
    on KargozarApiException catch (e) { if (mounted) setState(() => error = e.message); }
    catch (_) { if (mounted) setState(() => error = 'ارتباط با سرور برقرار نشد.'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) => AlertDialog(title: const Text('ورود به کارگزار'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('برای ثبت و پیگیری درخواست‌ها، شماره موبایل خود را تأیید کن.'),
      TextField(controller: mobile, enabled: !requested, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره موبایل')),
      if (requested) TextField(controller: code, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'کد یک‌بارمصرف')),
      if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
    ]),
    actions: [TextButton(onPressed: busy ? null : () => Navigator.pop(context, false), child: const Text('انصراف')),
      FilledButton(onPressed: busy ? null : submit, child: busy ? const CircularProgressIndicator() : Text(requested ? 'تأیید و ورود' : 'دریافت کد'))]);
}
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.catalog, required this.requests, required this.signedIn, required this.onLogin, required this.onLogout});
  final ServiceCatalogRepository catalog; final CustomerRequestRepository requests; final bool signedIn; final VoidCallback onLogin, onLogout;
  @override State<MainShell> createState() => _ShellState();
}
class _ShellState extends State<MainShell> {
  int index = 0;
  @override Widget build(BuildContext context) {
    final pages = [
      HomePage(catalog: widget.catalog, browse: () => setState(() => index = 1)),
      ServicesPage(catalog: widget.catalog, requests: widget.requests, signedIn: widget.signedIn, login: widget.onLogin),
      RequestsPage(repository: widget.requests, signedIn: widget.signedIn, login: widget.onLogin),
      ProfilePage(signedIn: widget.signedIn, login: widget.onLogin, logout: widget.onLogout),
    ];
    return Scaffold(body: SafeArea(child: pages[index]), bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v),
      destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), label: 'خانه'), NavigationDestination(icon: Icon(Icons.grid_view_outlined), label: 'خدمات'), NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'درخواست‌ها'), NavigationDestination(icon: Icon(Icons.person_outline), label: 'حساب من')]));
  }
}
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.catalog, required this.browse}); final ServiceCatalogRepository catalog; final VoidCallback browse;
  @override State<HomePage> createState() => _HomeState();
}
class _HomeState extends State<HomePage> {
  late Future<List<CatalogService>> future;
  @override void initState() { super.initState(); future = widget.catalog.getServices(); }
  @override Widget build(BuildContext context) => RefreshIndicator(onRefresh: () async { setState(() => future = widget.catalog.getServices()); await future; },
    child: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('کارگزار', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: navy)),
      const Text('همراه مطمئن کسب‌وکار شما', style: TextStyle(color: muted)),
      const SizedBox(height: 24),
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('شروع یک کسب‌وکار،\nبا مسیر روشن‌تر', style: TextStyle(color: Colors.white, fontSize: 23, height: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10), const Text('خدمات اداری و کسب‌وکار را آنلاین درخواست کنید و مراحل را پیگیری کنید.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16), FilledButton(onPressed: widget.browse, child: const Text('مشاهده خدمات'))])),
      const SizedBox(height: 22), const Text('خدمات پرکاربرد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      FutureBuilder<List<CatalogService>>(future: future, builder: (context, s) {
        if (s.hasError) return ErrorPanel(error: s.error, retry: () => setState(() => future = widget.catalog.getServices()));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        return Column(children: s.data!.take(4).map((v) => ListTile(title: Text(v.title), subtitle: Text(v.categoryName ?? ''), leading: const Icon(Icons.work_outline))).toList());
      }),
    ]));
}
class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key, required this.catalog, required this.requests, required this.signedIn, required this.login});
  final ServiceCatalogRepository catalog; final CustomerRequestRepository requests; final bool signedIn; final VoidCallback login;
  @override State<ServicesPage> createState() => _ServicesState();
}
class _ServicesState extends State<ServicesPage> {
  final search = TextEditingController(); late Future<List<CatalogService>> future;
  @override void initState() { super.initState(); future = widget.catalog.getServices(); }
  @override void dispose() { search.dispose(); super.dispose(); }
  void load() => setState(() => future = widget.catalog.getServices(query: search.text.trim()));
  Future<void> makeRequest(CatalogService service) async {
    if (!widget.signedIn) { widget.login(); return; }
    final note = await showDialog<String>(context: context, builder: (ctx) {
      final c = TextEditingController();
      return AlertDialog(title: Text('درخواست ' + service.title), content: TextField(controller: c, maxLines: 3, decoration: const InputDecoration(labelText: 'توضیحات اختیاری')),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('ثبت'))]);
    });
    if (note == null || !mounted) return;
    try {
      final key = DateTime.now().microsecondsSinceEpoch.toString() + '-' + Random.secure().nextInt(1 << 32).toString();
      final result = await widget.requests.create(serviceId: service.id, customerNote: note, idempotencyKey: key);
      if (mounted) showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('درخواست ثبت شد'), content: Text('کد پیگیری: ' + result.trackingCode), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('متوجه شدم'))]));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e)))); }
  }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('همه خدمات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
    TextField(controller: search, onSubmitted: (_) => load(), decoration: const InputDecoration(hintText: 'جست‌وجوی خدمات')),
    const SizedBox(height: 12),
    FutureBuilder<List<CatalogService>>(future: future, builder: (context, s) {
      if (s.hasError) return ErrorPanel(error: s.error, retry: load);
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      return Column(children: s.data!.map((v) => Card(color: Colors.white, child: ListTile(
        title: Text(v.title), subtitle: Text(v.description ?? v.categoryName ?? ''),
        trailing: const Icon(Icons.chevron_left), onTap: () => showModalBottomSheet<void>(context: context, builder: (ctx) => Padding(padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(v.description ?? 'برای ثبت درخواست این خدمت اقدام کنید.'),
          if (v.requirements.isNotEmpty) ...[const SizedBox(height: 10), const Text('مدارک لازم'), ...v.requirements.map((x) => Text('• ' + x))],
          const SizedBox(height: 16), SizedBox(width: double.infinity, child: FilledButton(onPressed: () { Navigator.pop(ctx); makeRequest(v); }, child: const Text('درخواست این خدمت'))),
        ]))))).toList());
    }),
  ]);
}
class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key, required this.repository, required this.signedIn, required this.login});
  final CustomerRequestRepository repository; final bool signedIn; final VoidCallback login;
  @override State<RequestsPage> createState() => _RequestsState();
}
class _RequestsState extends State<RequestsPage> {
  late Future<List<CustomerServiceRequest>> future;
  @override void initState() { super.initState(); future = widget.repository.getMine(); }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('درخواست‌های من', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
    if (!widget.signedIn) EmptyPanel(title: 'برای مشاهده درخواست‌ها وارد شو', action: FilledButton(onPressed: widget.login, child: const Text('ورود به حساب')))
    else FutureBuilder<List<CustomerServiceRequest>>(future: future, builder: (context, s) {
      if (s.hasError) return ErrorPanel(error: s.error, retry: () => setState(() => future = widget.repository.getMine()));
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      if (s.data!.isEmpty) return const EmptyPanel(title: 'هنوز درخواستی ثبت نکرده‌ای');
      return Column(children: s.data!.map((r) => Card(color: Colors.white, child: ListTile(title: Text(r.trackingCode), subtitle: Text('وضعیت: ' + r.status), onTap: () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: Text(r.trackingCode), content: Text('وضعیت: ' + r.status), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بستن'))])))).toList());
    }),
  ]);
}
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.signedIn, required this.login, required this.logout}); final bool signedIn; final VoidCallback login, logout;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('حساب کاربری', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
    ListTile(leading: const Icon(Icons.person), title: Text(signedIn ? 'حساب شما فعال است' : 'مهمان')),
    ListTile(leading: Icon(signedIn ? Icons.logout : Icons.login), title: Text(signedIn ? 'خروج از حساب' : 'ورود / ثبت‌نام'), onTap: signedIn ? logout : login),
    const ListTile(leading: Icon(Icons.support_agent), title: Text('پشتیبانی و تماس با ما')),
  ]);
}
class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.error, required this.retry}); final Object? error; final VoidCallback retry;
  @override Widget build(BuildContext context) => Column(children: [Text(errorText(error), textAlign: TextAlign.center), TextButton(onPressed: retry, child: const Text('تلاش دوباره'))]);
}
class EmptyPanel extends StatelessWidget {
  const EmptyPanel({super.key, required this.title, this.action}); final String title; final Widget? action;
  @override Widget build(BuildContext context) => Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [const Icon(Icons.inbox_outlined, size: 40), Text(title), if (action != null) action!])));
}
String errorText(Object? e) => e is KargozarApiException ? e.message : 'دریافت اطلاعات با مشکل روبه‌رو شد. نشانی سرور و اتصال اینترنت را بررسی کنید.';

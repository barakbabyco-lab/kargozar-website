import 'package:flutter/material.dart';
import 'core/network/kargozar_api_client.dart';
import 'features/catalog/service_catalog_repository.dart';

void main() {
  runApp(const KargozarApp());
}

const _navy = Color(0xFF142B4A);
const _teal = Color(0xFF168C83);
const _ink = Color(0xFF1E293B);
const _muted = Color(0xFF64748B);
const _canvas = Color(0xFFF5F7FA);

class KargozarApp extends StatelessWidget {
  const KargozarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'کارگزار',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _navy,
          primary: _navy,
          secondary: _teal,
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: _canvas,
          foregroundColor: _ink,
          centerTitle: false,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: MainShell(),
      ),
    );
  }
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
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _pages = const [
    HomePage(),
    ServicesPage(),
    RequestsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'خانه',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'خدمات',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'درخواست‌ها',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'حساب من',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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
                onPressed: () => _showInfo(context),
                child: const Text('ثبت درخواست مشاوره رایگان'),
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
                  ServiceCard(service: items[index]),
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
        const Text(
          'نسخه آزمایشی — ثبت درخواست و اطلاعات در این مرحله نمایشی است.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 11),
        ),
      ],
    );
  }
}

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  String _query = '';
  late final KargozarApiClient _api;
  late final ServiceCatalogRepository _catalog;
  late Future<List<CatalogService>> _remoteServices;
  late Future<List<ServiceCategory>> _remoteCategories;
  String? _selectedCategory;
  bool _apiConfigured = false;

  @override
  void initState() {
    super.initState();
    _api = KargozarApiClient();
    _catalog = ServiceCatalogRepository(_api);
    _apiConfigured = const String.fromEnvironment('API_BASE_URL').trim().isNotEmpty;
    _remoteServices = _apiConfigured
        ? _catalog.getServices()
        : Future.value(const <CatalogService>[]);
    _remoteCategories = _apiConfigured
        ? _catalog.getCategoryTree()
        : Future.value(const <ServiceCategory>[]);
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  void _retryRemote() {
    setState(() => _remoteServices = _catalog.getServices(
      category: _selectedCategory,
      query: _query,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = services.where((item) =>
      item.title.contains(_query) ||
      item.category.contains(_query) ||
      item.subtitle.contains(_query)).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('همه خدمات', style: TextStyle(
          color: _ink, fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        const Text('خدمت موردنظرت را جست‌وجو و انتخاب کن.',
            style: TextStyle(color: _muted)),
        const SizedBox(height: 18),
        TextField(
          textDirection: TextDirection.rtl,
          onChanged: (value) {
            setState(() => _query = value.trim());
          },
          onSubmitted: (_) {
            if (_apiConfigured) _retryRemote();
          },
          decoration: const InputDecoration(
            hintText: 'جست‌وجوی خدمات...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 15),
        if (_apiConfigured) ...[
          FutureBuilder<List<ServiceCategory>>(
            future: _remoteCategories,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextButton.icon(
                    onPressed: () => setState(
                      () => _remoteCategories = _catalog.getCategoryTree(),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('بارگذاری دسته‌بندی‌ها دوباره تلاش شود'),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                );
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8EDF3)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      selected: _selectedCategory == null,
                      leading: const Icon(Icons.apps_rounded, color: _teal),
                      title: const Text('همه دسته‌بندی‌ها',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      onTap: () {
                        setState(() => _selectedCategory = null);
                        _retryRemote();
                      },
                    ),
                    ...snapshot.data!.map((category) => _CatalogCategoryBranch(
                      category: category,
                      selectedSlug: _selectedCategory,
                      onSelected: (slug) {
                        setState(() => _selectedCategory = slug);
                        _retryRemote();
                      },
                    )),
                  ],
                ),
              );
            },
          ),
        ],
        if (_apiConfigured)
          FutureBuilder<List<CatalogService>>(
            future: _remoteServices,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('دریافت فهرست زنده خدمات ممکن نشد.',
                          style: TextStyle(color: _ink, fontSize: 12)),
                      TextButton(
                        onPressed: _retryRemote,
                        child: const Text('تلاش دوباره'),
                      ),
                    ],
                  ),
                );
              }
              final items = snapshot.data ?? const <CatalogService>[];
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('در حال حاضر خدمتی در کاتالوگ آنلاین ثبت نشده است.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted)),
                );
              }
              return Column(
                children: items.map((item) {
                  final service = _serviceItemFromCatalog(item);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ServiceListTile(service: service),
                  );
                }).toList(),
              );
            },
          )
        else ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'اتصال به سرور هنوز تنظیم نشده؛ فهرست زیر صرفاً نمونه نمایشی است.',
              style: TextStyle(color: _ink, fontSize: 11),
            ),
          ),
          ...filtered.map((service) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ServiceListTile(service: service),
          )),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Text('خدمتی با این عبارت پیدا نشد.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted)),
            ),
        ],
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

class _CatalogCategoryBranch extends StatelessWidget {
  const _CatalogCategoryBranch({
    required this.category,
    required this.selectedSlug,
    required this.onSelected,
  });

  final ServiceCategory category;
  final String? selectedSlug;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final title = Text(category.name,
        style: const TextStyle(fontSize: 12, color: _ink));
    if (category.children.isEmpty) {
      return ListTile(
        dense: true,
        contentPadding: const EdgeInsetsDirectional.only(start: 30, end: 14),
        selected: selectedSlug == category.slug,
        leading: const Icon(Icons.subdirectory_arrow_left_rounded,
            size: 17, color: _teal),
        title: title,
        onTap: () => onSelected(category.slug),
      );
    }
    return ExpansionTile(
      tilePadding: const EdgeInsetsDirectional.only(start: 14, end: 14),
      childrenPadding: const EdgeInsetsDirectional.only(start: 10),
      title: title,
      children: [
        ListTile(
          dense: true,
          selected: selectedSlug == category.slug,
          title: Text('همه خدمات ${category.name}',
              style: const TextStyle(fontSize: 12, color: _muted)),
          onTap: () => onSelected(category.slug),
        ),
        ...category.children.map((child) => _CatalogCategoryBranch(
          category: child,
          selectedSlug: selectedSlug,
          onSelected: onSelected,
        )),
      ],
    );
  }
}

IconData _iconForCategory(String? category) {
  final value = category ?? '';
  if (value.contains('مجوز') || value.contains('بهداشتی')) return Icons.storefront_outlined;
  if (value.contains('ثبت') || value.contains('برند')) return Icons.verified_outlined;
  if (value.contains('بانک')) return Icons.account_balance_outlined;
  if (value.contains('قرارداد') || value.contains('حقوقی')) return Icons.description_outlined;
  if (value.contains('آنلاین') || value.contains('اینترنت')) return Icons.shopping_bag_outlined;
  return Icons.work_outline_rounded;
}

class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Text('درخواست‌های من', style: TextStyle(
          color: _ink, fontSize: 25, fontWeight: FontWeight.w900)),
        SizedBox(height: 8),
        Text('وضعیت درخواست‌هایت را از این قسمت پیگیری می‌کنی.',
            style: TextStyle(color: _muted, height: 1.8)),
        SizedBox(height: 24),
        EmptyState(
          icon: Icons.inbox_outlined,
          title: 'هنوز درخواستی ثبت نکرده‌ای',
          subtitle: 'بعد از ثبت درخواست، کد پیگیری و آخرین وضعیت اینجا نمایش داده می‌شود.',
        ),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('حساب کاربری', style: TextStyle(
          color: _ink, fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFE8EEF5),
                child: Icon(Icons.person_outline, color: _navy, size: 28),
              ),
              SizedBox(width: 13),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مهمان', style: TextStyle(
                    color: _ink, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('برای استفاده از خدمات وارد شوید',
                      style: TextStyle(color: _muted, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const ProfileOption(icon: Icons.support_agent, title: 'پشتیبانی و تماس با ما'),
        const ProfileOption(icon: Icons.policy_outlined, title: 'قوانین و حریم خصوصی'),
        const ProfileOption(icon: Icons.info_outline, title: 'درباره کارگزار'),
      ],
    );
  }
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
  const ServiceCard({super.key, required this.service});
  final ServiceItem service;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: () => _showService(context, service),
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
  const ServiceListTile({super.key, required this.service});
  final ServiceItem service;

  @override
  Widget build(BuildContext context) => ListTile(
    tileColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    leading: CircleAvatar(
      backgroundColor: const Color(0xFFEAF4F3),
      child: Icon(service.icon, color: _teal),
    ),
    title: Text(service.title, style: const TextStyle(
      fontWeight: FontWeight.w800, color: _ink, fontSize: 14)),
    subtitle: Text(service.subtitle, style: const TextStyle(
      color: _muted, fontSize: 11, height: 1.7)),
    trailing: const Icon(Icons.chevron_left_rounded, color: _muted),
    onTap: () => _showService(context, service),
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
          backgroundColor: const Color(0xFFE5F2F0),
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

void _showService(BuildContext context, ServiceItem service) {
  final pageContext = context;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 42, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(5)))),
          const SizedBox(height: 22),
          Icon(service.icon, color: _teal, size: 34),
          const SizedBox(height: 14),
          Text(service.title, style: const TextStyle(
            color: _ink, fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 8),
          Text(service.subtitle, style: const TextStyle(
            color: _muted, height: 1.8)),
          if (service.estimatedDays != null || service.basePrice != null) ...[
            const SizedBox(height: 14),
            if (service.estimatedDays != null)
              _ServiceMetaRow(
                icon: Icons.schedule_outlined,
                label: 'زمان تخمینی انجام',
                value: '${service.estimatedDays} روز کاری',
              ),
            if (service.basePrice != null)
              _ServiceMetaRow(
                icon: Icons.payments_outlined,
                label: 'قیمت پایه (نیازمند تأیید)',
                value: service.basePrice!.toString(),
              ),
          ],
          if (service.requirements.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('مدارک و اطلاعات موردنیاز',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            ...service.requirements.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(color: _teal)),
                  Expanded(child: Text(item,
                      style: const TextStyle(color: _muted, height: 1.6))),
                ],
              ),
            )),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _showRequestForm(pageContext, service);
              },
              child: const Text('درخواست این خدمت'),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'این فرم صرفاً پیش‌نمایش است و اطلاعات را به سرور ارسال نمی‌کند.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 10)),
        ],
      ),
    ),
  );
}


void _showRequestForm(BuildContext context, ServiceItem service) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetContext) => _RequestForm(
      service: service, hostContext: context),
  );
}

class _RequestForm extends StatefulWidget {
  const _RequestForm({required this.service, required this.hostContext});
  final ServiceItem service;
  final BuildContext hostContext;

  @override
  State<_RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends State<_RequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _details = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22, 24, 22, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('درخواست ${widget.service.title}',
                style: const TextStyle(
                  color: _ink, fontWeight: FontWeight.w900, fontSize: 19)),
              const SizedBox(height: 8),
              const Text(
                'برای آشنایی با روند ثبت درخواست، فرم نمونه را تکمیل کن.',
                style: TextStyle(color: _muted, height: 1.8, fontSize: 12)),
              const SizedBox(height: 18),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'نام و نام خانوادگی'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'نام را وارد کن' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'شماره موبایل'),
                validator: (v) => (v == null || !RegExp(r'^09\d{9}$').hasMatch(v.trim()))
                    ? 'شماره موبایل معتبر وارد کن' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _details,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'توضیحات درخواست (اختیاری)'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    Navigator.pop(context);
                    showDialog<void>(
                      context: widget.hostContext,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('پیش‌نمایش تکمیل فرم'),
                        content: const Text(
                          'فرم آزمایشی تکمیل شد؛ اما هنوز به سرور متصل نیست و هیچ اطلاعاتی ذخیره یا ارسال نشده است. در نسخه عملیاتی، این مرحله به ثبت درخواست و صدور کد پیگیری متصل می‌شود.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('متوجه شدم'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('بررسی فرم آزمایشی'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'اطلاعات واقعی یا مدارک هویتی وارد نکن؛ این فرم هنوز آزمایشی است.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

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

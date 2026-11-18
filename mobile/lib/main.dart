import 'package:flutter/material.dart';

void main() => runApp(const KargozarApp());

const _navy = Color(0xFF142B4A);
const _teal = Color(0xFF168C83);
const _ink = Color(0xFF1E293B);
const _muted = Color(0xFF64748B);
const _canvas = Color(0xFFF5F7FA);
const _line = Color(0xFFE7ECF2);

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
        appBarTheme: const AppBarTheme(
          backgroundColor: _canvas,
          foregroundColor: _ink,
          elevation: 0,
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: MainShell(),
      ),
    );
  }
}

class ServiceCategory {
  const ServiceCategory({
    required this.title,
    required this.description,
    required this.icon,
    required this.items,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<String> items;
}

// Presentation catalogue for the first UI milestone.
// The production catalogue will be loaded from the Laravel service-catalog API.
const serviceCategories = <ServiceCategory>[
  ServiceCategory(
    title: 'مجوزهای کسب‌وکار',
    description: 'مسیر دریافت مجوزهای موردنیاز برای شروع، فعالیت یا توسعه کسب‌وکار؛ متناسب با نوع فعالیت و مرجع صادرکننده.',
    icon: Icons.storefront_outlined,
    items: [
      'جواز کسب‌وکار مشاغل خانگی',
      'جواز کسب‌وکار صنفی',
      'جواز کسب‌وکار دستگاهی',
      'کارت بازرگانی',
    ],
  ),
  ServiceCategory(
    title: 'ثبت شرکت',
    description: 'خدمات ثبت، تغییرات و امور ثبتی شرکت‌ها و مؤسسات، از مرحله تأسیس تا انحلال و تصفیه.',
    icon: Icons.apartment_rounded,
    items: [
      'ثبت و تأسیس شرکت',
      'ثبت مؤسسات غیرتجاری',
      'تغییرات شرکت‌ها و مؤسسات',
      'انحلال و تصفیه شرکت',
      'ثبت شعبه و نمایندگی',
      'دریافت دفاتر قانونی و پلمپ دفاتر',
      'سایر امور ثبتی شرکت‌ها',
    ],
  ),
  ServiceCategory(
    title: 'ثبت برند و مالکیت فکری',
    description: 'حفاظت و ثبت نام و نشان تجاری، اختراع، طرح صنعتی و آثار فکری و هنری.',
    icon: Icons.workspace_premium_outlined,
    items: [
      'ثبت علامت تجاری (برند)',
      'تمدید و تجدید ثبت برند',
      'انتقال و تغییرات برند',
      'ثبت طرح صنعتی',
      'ثبت اختراع',
      'ثبت آثار ادبی و هنری',
      'جست‌وجو و استعلام مالکیت فکری',
      'خدمات حقوقی و پیگیری مالکیت فکری',
      'سایر خدمات مالکیت فکری',
    ],
  ),
  ServiceCategory(
    title: 'مدارک و تأییدیه‌های مکمل',
    description: 'مدارک، گواهی‌ها و تأییدیه‌هایی که بسته به نوع فعالیت در کنار مجوز اصلی کسب‌وکار لازم می‌شوند.',
    icon: Icons.verified_user_outlined,
    items: [
      'کارت بهداشت',
      'تأییدیه بهداشت محیط',
      'تأییدیه پلیس اماکن',
      'گواهی احکام تجارت',
      'گواهینامه فنی و حرفه‌ای',
      'نشان استاندارد',
      'سیب سلامت',
      'تشکیل پرونده و دریافت کد رهگیری مالیاتی',
    ],
  ),
  ServiceCategory(
    title: 'خدمات بانکی',
    description: 'پیگیری خدمات بانکی موردنیاز اشخاص و کسب‌وکارها با توجه به ضوابط بانک و شرایط متقاضی.',
    icon: Icons.account_balance_outlined,
    items: [
      'افتتاح حساب جاری و دریافت دسته‌چک',
      'دریافت تسهیلات بانکی',
      'دریافت دستگاه کارت‌خوان (POS)',
      'دریافت دستگاه کش‌لس (Cashless)',
    ],
  ),
  ServiceCategory(
    title: 'خدمات حقوقی و قراردادی',
    description: 'تنظیم، بررسی و پیگیری قراردادها و اسناد حقوقی مرتبط با فعالیت‌های کاری و تجاری.',
    icon: Icons.gavel_outlined,
    items: [
      'تنظیم قراردادهای کاری',
      'تنظیم قراردادهای پیمانکاری',
      'قراردادهای تجاری و بازرگانی',
      'قراردادهای مشارکت',
      'امور حقوقی و مشاوره',
      'امور مالیاتی و بیمه‌ای مرتبط با قراردادها',
      'تنظیم اسناد و توافق‌نامه‌ها',
      'سایر خدمات حقوقی و قراردادی',
    ],
  ),
  ServiceCategory(
    title: 'خدمات اینترنتی و تجاری',
    description: 'راه‌اندازی زیرساخت حضور و فروش آنلاین و ابزارهای ارتباطی موردنیاز کسب‌وکار.',
    icon: Icons.language_rounded,
    items: [
      'ثبت و راه‌اندازی کسب‌وکار اینترنتی',
      'طراحی و راه‌اندازی وب‌سایت',
      'خدمات دامنه و میزبانی',
      'خدمات تلفن و ارتباطات اینترنتی',
      'خدمات پیامکی',
      'خدمات فروش و تجارت الکترونیک',
      'سایر خدمات اینترنتی و تجاری',
    ],
  ),
  ServiceCategory(
    title: 'خدمات ملکی و قراردادها',
    description: 'تنظیم و پیگیری قراردادهای مرتبط با معاملات و روابط ملکی.',
    icon: Icons.real_estate_agent_outlined,
    items: [
      'قرارداد اجاره‌نامه کد رهگیری‌دار',
      'مبایعه‌نامه املاک',
      'تمدید اجاره‌نامه و دریافت کد رهگیری جدید',
      'قرارداد مشارکت در ساخت',
      'قرارداد پیش‌فروش ملک',
      'الحاقیه و اصلاح قراردادهای ملکی',
      'فسخ و اقاله قراردادهای ملکی',
      'بررسی و مشاوره حقوقی قراردادهای ملکی',
    ],
  ),
  ServiceCategory(
    title: 'خدمات توسعه کسب‌وکار',
    description: 'ابزارها و راهکارهای مدیریتی برای منظم‌تر شدن فروش، امور مالی، منابع انسانی و عملیات روزانه.',
    icon: Icons.query_stats_rounded,
    items: [
      'نرم‌افزار حسابداری و مالی',
      'صدور فاکتور و مدیریت فروش',
      'حقوق و دستمزد و مدیریت پرسنل',
      'مدیریت منابع انسانی',
      'مدیریت قراردادها',
      'مدیریت ارتباط با مشتریان (CRM)',
      'مدیریت انبار و موجودی کالا',
      'مدیریت سفارش‌ها و خرید',
      'سیستم مدیریت کسب‌وکار و گزارش‌گیری',
      'سایر ابزارها و نرم‌افزارهای مدیریتی',
    ],
  ),
  ServiceCategory(
    title: 'سایر خدمات تخصصی',
    description: 'خدمات تخصصی مکمل و موضوعات جدیدی که در دسته‌های دیگر قرار نمی‌گیرند.',
    icon: Icons.lightbulb_outline_rounded,
    items: [
      'مشاوره تخصصی کسب‌وکار',
      'تدوین طرح توجیهی و امکان‌سنجی',
      'تهیه طرح کسب‌وکار (Business Plan)',
      'ارزش‌گذاری کسب‌وکار',
      'خدمات تأمین سرمایه و جذب سرمایه‌گذار',
      'خدمات صادرات و واردات تخصصی',
      'آموزش و مشاوره تخصصی مشاغل',
      'سایر خدمات قابل ارائه توسط کارگزار',
    ],
  ),
];

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 1;

  final _pages = const <Widget>[
    ProfilePage(),
    ServicesPage(),
    CompanionPage(),
    SupportPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'پروفایل من',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'خدمات',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_mosaic_outlined),
            selectedIcon: Icon(Icons.auto_awesome_mosaic_rounded),
            label: 'همراه کسب‌وکار',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent_rounded),
            label: 'ارتباط و پشتیبانی',
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    final filtered = serviceCategories.where((category) {
      final q = _query.trim();
      if (q.isEmpty) return true;
      return category.title.contains(q) ||
          category.description.contains(q) ||
          category.items.any((item) => item.contains(q));
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _navy,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.handshake_outlined,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'کارگزار',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'همراه مطمئن کسب‌وکار شما',
                          style: TextStyle(color: _muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'اعلان‌ها',
                    onPressed: () => _showNotice(context),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'سلام، خوش آمدید',
                style: TextStyle(
                  color: _ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'چه خدمتی برای کسب‌وکارتان نیاز دارید؟',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 17),
              TextField(
                textDirection: TextDirection.rtl,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'جست‌وجوی خدمات موردنیاز...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _line),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _ConsultationCard(onTap: () => _showNotice(context)),
              const SizedBox(height: 25),
              const Text(
                'دسته‌بندی خدمات',
                style: TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'خدمات موردنیازتان را مستقل و به‌دلخواه انتخاب کنید.',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.7),
              ),
              const SizedBox(height: 15),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.crossAxisExtent;
              final columns = width > 560 ? 3 : 2;
              return SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _CategoryCard(
                    category: filtered[index],
                    onTap: () => _showCategory(context, filtered[index]),
                  ),
                  childCount: filtered.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 11,
                  mainAxisSpacing: 11,
                  childAspectRatio: 1.12,
                ),
              );
            },
          ),
        ),
        if (filtered.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'دسته‌ای با این عبارت پیدا نشد.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  const _ConsultationCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF4F3),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: _teal,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مشاوره رایگان',
                      style: TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'برای انتخاب بهترین مسیر، از ما راهنمایی بگیرید.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 11,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              const Icon(Icons.chevron_left_rounded, color: _teal),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});
  final ServiceCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: _teal, size: 22),
              ),
              const Spacer(),
              Text(
                category.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  height: 1.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${category.items.length} زیرشاخه',
                    style: const TextStyle(color: _muted, fontSize: 10),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_back_rounded,
                    color: _teal,
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showCategory(BuildContext context, ServiceCategory category) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4F3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(category.icon, color: _teal, size: 27),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.title,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _canvas,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              category.description,
              style: const TextStyle(
                color: _muted,
                height: 1.9,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'خدمات این دسته',
            style: TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...category.items.asMap().entries.map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _line),
                borderRadius: BorderRadius.circular(13),
              ),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 15,
                  backgroundColor: const Color(0xFFEAF4F3),
                  child: Text(
                    '${entry.key + 1}',
                    style: const TextStyle(
                      color: _teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                title: Text(
                  entry.value,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_left_rounded,
                  color: _muted,
                  size: 19,
                ),
                onTap: () => _showNotice(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'فهرست و جزئیات رسمی هر خدمت در مرحله تکمیل کاتالوگ به‌روزرسانی می‌شود.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 10, height: 1.7),
          ),
        ],
      ),
    ),
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => _SimplePage(
    icon: Icons.person_outline_rounded,
    title: 'پروفایل من',
    description:
        'اطلاعات شخصی و کسب‌وکار، پرونده‌ها، مدارک، خدمات دریافت‌شده و مسیر انجام درخواست‌ها در این بخش قرار می‌گیرد.',
  );
}

class CompanionPage extends StatelessWidget {
  const CompanionPage({super.key});

  @override
  Widget build(BuildContext context) => _SimplePage(
    icon: Icons.auto_awesome_mosaic_outlined,
    title: 'خدمات همراه کسب‌وکار',
    description:
        'طراحی هویت بصری، تبلیغات، تولید محتوا، طراحی وب‌سایت و ابزارهای معرفی و توسعه برند در این بخش ارائه می‌شود.',
  );
}

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) => _SimplePage(
    icon: Icons.support_agent_rounded,
    title: 'ارتباط و پشتیبانی',
    description:
        'گفت‌وگو با کارشناس، درخواست تماس، راهنمایی و دستیار هوشمند کارگزار از این بخش در دسترس خواهد بود.',
  );
}

class _SimplePage extends StatelessWidget {
  const _SimplePage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const SizedBox(height: 18),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF4F3),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Icon(icon, color: _teal, size: 31),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(
            color: _navy,
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          description,
          style: const TextStyle(color: _muted, height: 2, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _line),
          ),
          child: const Text(
            'ساختار این بخش در مراحل بعدی طراحی و به امکانات عملیاتی متصل می‌شود.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.8),
          ),
        ),
      ],
    );
  }
}

void _showNotice(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('در حال آماده‌سازی'),
      content: const Text(
        'این امکان در نسخه بعدی به فرایند واقعی ثبت درخواست و ارتباط با کارشناسان متصل می‌شود.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('متوجه شدم'),
        ),
      ],
    ),
  );
}

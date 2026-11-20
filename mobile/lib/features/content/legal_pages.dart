import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _brand = Color(0xFFC62828);
const _ink = Color(0xFF1E293B);
const _muted = Color(0xFF64748B);

class KargozarAboutPage extends StatelessWidget {
  const KargozarAboutPage({super.key});

  @override
  Widget build(BuildContext context) => const _LegalPage(
    title: 'درباره کارگزار',
    intro: 'کارگزار، همراه کسب‌وکارها برای دریافت خدمات اداری، ثبتی و راهکارهای توسعه کسب‌وکار است.',
    sections: [
      _LegalSection(
        title: 'معرفی',
        body: 'کارگزار با هدف ساده‌سازی دسترسی به خدمات موردنیاز اشخاص و کسب‌وکارها فعالیت می‌کند. در این مسیر، اطلاعات اولیه خدمات، راهنمایی درباره مراحل و ارتباط با کارشناسان در یک مسیر روشن در اختیار متقاضی قرار می‌گیرد.',
      ),
      _LegalSection(
        title: 'شیوه ارائه خدمات',
        body: 'خدمات کارگزار برای متقاضیان در سراسر ایران قابل پیگیری است و تا حد امکان به‌صورت غیرحضوری ارائه می‌شود. جزئیات هر خدمت، مدارک موردنیاز، هزینه و زمان انجام پس از بررسی شرایط متقاضی و پیش از شروع کار اعلام خواهد شد.',
      ),
      _LegalSection(
        title: 'مسئول ارائه خدمات',
        body: 'خدمات تحت نام تجاری «کارگزار» و توسط شرکت نوباوگان شکوه بارانا ارائه می‌شود.',
      ),
    ],
  );
}

class KargozarPrivacyPage extends StatelessWidget {
  const KargozarPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) => const _LegalPage(
    title: 'سیاست حفظ حریم خصوصی',
    intro: 'این صفحه توضیح می‌دهد اپلیکیشن فعلی کارگزار چه اطلاعاتی را دریافت می‌کند و چگونه از آن استفاده می‌شود.',
    sections: [
      _LegalSection(
        title: '۱. اطلاعات حساب و ثبت درخواست',
        body: 'در نسخه فعلی، برای مشاهده دسته‌بندی‌ها و معرفی خدمات نیازی به ایجاد حساب، ثبت‌نام، ورود با رمز یک‌بارمصرف یا ثبت درخواست آنلاین نیست. اپلیکیشن در این مسیرها اطلاعات هویتی یا اطلاعات تماس از کاربر دریافت نمی‌کند.',
      ),
      _LegalSection(
        title: '۲. تماس و ارتباط با کارگزار',
        body: 'با انتخاب دکمه تماس، شماره‌گیر دستگاه با شماره کارگزار باز می‌شود. برقراری تماس با تصمیم کاربر انجام می‌شود. اپلیکیشن بدون اقدام کاربر تماس تلفنی برقرار نمی‌کند.',
      ),
      _LegalSection(
        title: '۳. اطلاعات فنی',
        body: 'زیرساخت میزبانی ممکن است اطلاعات فنی متعارف درخواست‌های شبکه را برای امنیت، پایداری و عیب‌یابی پردازش کند. این اطلاعات به‌منظور ایجاد حساب یا ثبت سفارش در اپلیکیشن استفاده نمی‌شوند.',
      ),
      _LegalSection(
        title: '۴. دسترسی‌های دستگاه',
        body: 'برای مشاهده محتوای نسخه فعلی، دسترسی به مخاطبان، پیامک‌ها، گزارش تماس، میکروفن یا موقعیت مکانی لازم نیست. انتخاب گزینه تماس، شماره‌گیر دستگاه را باز می‌کند.',
      ),
      _LegalSection(
        title: '۵. اشتراک‌گذاری و نگهداری اطلاعات',
        body: 'اپلیکیشن در نسخه فعلی فرم ثبت سفارش، گفت‌وگوی پشتیبانی، بارگذاری مدارک یا پرداخت آنلاین ندارد. اطلاعات فنی احتمالی مطابق نیازهای امنیتی، عیب‌یابی و الزامات قانونی توسط زیرساخت مربوط پردازش می‌شوند.',
      ),
      _LegalSection(
        title: '۶. تغییرات سیاست',
        body: 'در صورت اضافه‌شدن قابلیت‌هایی که به دریافت اطلاعات شخصی نیاز داشته باشند، سیاست حریم خصوصی متناسب با قابلیت جدید به‌روزرسانی و پیش از فعال‌سازی آن اطلاع‌رسانی می‌شود.',
      ),
      _LegalSection(
        title: '۷. ارتباط درباره حریم خصوصی',
        body: 'برای طرح پرسش یا درخواست مرتبط با حریم خصوصی می‌توانید با شماره رسمی کارگزار تماس بگیرید.',
      ),
    ],
  );
}

class KargozarTermsPage extends StatelessWidget {
  const KargozarTermsPage({super.key});

  @override
  Widget build(BuildContext context) => const _LegalPage(
    title: 'قوانین و شرایط استفاده',
    intro: 'استفاده از اپلیکیشن کارگزار به معنی پذیرش شرایط زیر است.',
    sections: [
      _LegalSection(
        title: '۱. ماهیت اپلیکیشن',
        body: 'نسخه فعلی اپلیکیشن برای معرفی دسته‌بندی‌ها و خدمات، ارائه اطلاعات اولیه و فراهم‌کردن راه ارتباط با کارگزار طراحی شده است. در این نسخه ثبت سفارش آنلاین، پرداخت، بارگذاری مدارک و پیگیری پرونده درون برنامه فعال نیست.',
      ),
      _LegalSection(
        title: '۲. اعتبار اطلاعات خدمات',
        body: 'اطلاعات نمایش‌داده‌شده جنبه راهنمایی اولیه دارد. شرایط، مدارک، هزینه‌ها و زمان انجام هر خدمت ممکن است با توجه به نوع فعالیت، محل، مقررات روز و نظر مرجع صادرکننده تغییر کند. جزئیات نهایی پس از بررسی مورد اعلام می‌شود.',
      ),
      _LegalSection(
        title: '۳. عدم تضمین نتیجه اداری',
        body: 'تصمیم نهایی درباره صدور مجوز، تأییدیه یا ثبت هر موضوع با مرجع قانونی و ذی‌صلاح است. معرفی یا پیگیری یک خدمت به معنی تضمین صدور مجوز یا تأیید نتیجه از سوی کارگزار نیست.',
      ),
      _LegalSection(
        title: '۴. هزینه و شروع خدمت',
        body: 'شرح خدمات، مبلغ قابل پرداخت، مدارک لازم و تعهدات طرفین پیش از شروع عملیات اجرایی به متقاضی اعلام می‌شود. صرف مشاهده اطلاعات یا انتخاب دکمه تماس به معنی ثبت سفارش یا ایجاد تعهد مالی نیست.',
      ),
      _LegalSection(
        title: '۵. مسئولیت اطلاعات ارائه‌شده',
        body: 'متقاضی مسئول صحت و کامل‌بودن اطلاعات و مدارکی است که در ارتباط با کارشناسان ارائه می‌کند. ارائه اطلاعات نادرست یا ناقص می‌تواند بر امکان‌پذیری، هزینه و زمان انجام خدمت اثر بگذارد.',
      ),
      _LegalSection(
        title: '۶. تغییر شرایط',
        body: 'کارگزار می‌تواند در صورت تغییر مقررات، فرایندهای مراجع رسمی یا امکانات سامانه، اطلاعات معرفی خدمات و این شرایط را به‌روزرسانی کند.',
      ),
      _LegalSection(
        title: '۷. ارتباط با کارگزار',
        body: 'برای دریافت توضیحات تکمیلی درباره هر خدمت یا شرایط استفاده، از راه‌های ارتباطی درج‌شده در اپلیکیشن استفاده کنید.',
      ),
    ],
  );
}

class _LegalSection {
  const _LegalSection({required this.title, required this.body});
  final String title;
  final String body;
}

class _LegalPage extends StatelessWidget {
  const _LegalPage({
    required this.title,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String intro;
  final List<_LegalSection> sections;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF4D6D6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: _brand, size: 28),
                  const SizedBox(height: 10),
                  Text(title, style: const TextStyle(color: _ink, fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(intro, style: const TextStyle(color: _muted, height: 1.9, fontSize: 13)),
                  const SizedBox(height: 8),
                  const Text('آخرین به‌روزرسانی: ۲۹ آبان ۱۴۰۵', style: TextStyle(color: _muted, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...sections.map((section) => Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(section.body, style: const TextStyle(color: _muted, height: 2, fontSize: 13)),
                ],
              ),
            )),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => launchUrl(Uri(scheme: 'tel', path: '09365952800')),
                icon: const Icon(Icons.call_outlined),
                label: const Text('تماس با کارگزار'),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('۰۹۳۶۵۹۵۲۸۰۰', style: TextStyle(color: _muted, fontSize: 12))),
          ],
        ),
      ),
    ),
  );
}

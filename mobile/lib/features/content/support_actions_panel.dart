import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _supportPhone = String.fromEnvironment(
  'KARGOZAR_SUPPORT_PHONE',
  defaultValue: '09360952800',
);
const _supportEmail = String.fromEnvironment(
  'KARGOZAR_SUPPORT_EMAIL',
  defaultValue: 'info@kargozarr.ir',
);
const _websiteUri = 'https://kargozarr.ir/';

class SupportActionsPanel extends StatelessWidget {
  const SupportActionsPanel({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('امکان باز کردن این مسیر وجود ندارد.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneReady = _supportPhone.trim().isNotEmpty;
    final emailReady = _supportEmail.trim().isNotEmpty;
    return Column(
      children: [
        _SupportAction(
          icon: Icons.call_outlined,
          title: 'تماس تلفنی با پشتیبان',
          subtitle: phoneReady ? _supportPhone : 'پس از ثبت شماره پشتیبانی فعال می‌شود',
          enabled: phoneReady,
          onTap: phoneReady
              ? () => _open(context, Uri(scheme: 'tel', path: _supportPhone.trim()))
              : null,
        ),
        _SupportAction(
          icon: Icons.email_outlined,
          title: 'ارسال ایمیل به پشتیبانی',
          subtitle: emailReady ? _supportEmail : 'پس از ثبت ایمیل پشتیبانی فعال می‌شود',
          enabled: emailReady,
          onTap: emailReady
              ? () => _open(context, Uri(scheme: 'mailto', path: _supportEmail.trim()))
              : null,
        ),
        _SupportAction(
          icon: Icons.article_outlined,
          title: 'وب‌سایت و مقالات کارگزار',
          subtitle: 'مطالعه مطالب و آشنایی با خدمات',
          onTap: () => _open(context, Uri.parse(_websiteUri)),
        ),
        const _SupportAction(
          icon: Icons.chat_outlined,
          title: 'گفت‌وگوی آنلاین',
          subtitle: 'در مرحله راه‌اندازی زیرساخت',
          enabled: false,
          trailingLabel: 'به‌زودی',
        ),
        const _SupportAction(
          icon: Icons.smart_toy_outlined,
          title: 'دستیار هوشمند',
          subtitle: 'پس از اتصال سرویس هوش مصنوعی فعال می‌شود',
          enabled: false,
          trailingLabel: 'به‌زودی',
        ),
      ],
    );
  }
}

class _SupportAction extends StatelessWidget {
  const _SupportAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.enabled = true,
    this.onTap,
    this.trailingLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) => Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 9),
        child: ListTile(
          enabled: enabled,
          leading: Icon(icon, color: enabled ? const Color(0xFFC62828) : const Color(0xFF9CA3AF)),
          title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
          trailing: trailingLabel == null
              ? const Icon(Icons.chevron_left)
              : Text(trailingLabel!, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
          onTap: enabled ? onTap : null,
        ),
      );
}

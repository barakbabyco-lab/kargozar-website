import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _supportPhone=String.fromEnvironment('KARGOZAR_SUPPORT_PHONE',defaultValue:'09360952800');
const _supportEmail=String.fromEnvironment('KARGOZAR_SUPPORT_EMAIL',defaultValue:'info@kargozarr.ir');
const _websiteUri='https://kargozarr.ir/';

class SupportActionsPanel extends StatelessWidget {
 const SupportActionsPanel({super.key});
 Future<void> _open(BuildContext context,Uri uri)async{final ok=await launchUrl(uri,mode:LaunchMode.externalApplication);if(!ok&&context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('امکان باز کردن این مسیر وجود ندارد.')));}
 @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Column(children:[
  _Action(icon:Icons.call_outlined,title:'تماس تلفنی با پشتیبان',subtitle:_supportPhone,onTap:()=>_open(context,Uri(scheme:'tel',path:_supportPhone))),
  const _Action(icon:Icons.confirmation_number_outlined,title:'ارسال پیام به پشتیبانی و ثبت تیکت',subtitle:'ثبت تیکت پس از راه‌اندازی زیرساخت فعال می‌شود',enabled:false,tag:'به‌زودی'),
  const _Action(icon:Icons.chat_outlined,title:'ارتباط آنلاین با پشتیبانی',subtitle:'در حال آماده‌سازی',enabled:false,tag:'به‌زودی'),
  const _Action(icon:Icons.smart_toy_outlined,title:'دستیار هوشمند',subtitle:'پس از اتصال سرویس هوش مصنوعی فعال می‌شود',enabled:false,tag:'به‌زودی'),
  _Action(icon:Icons.email_outlined,title:'ارسال ایمیل',subtitle:_supportEmail,onTap:()=>_open(context,Uri(scheme:'mailto',path:_supportEmail))),
  _Action(icon:Icons.article_outlined,title:'وبلاگ و مقالات کارگزار',subtitle:'مطالعه مطالب و آشنایی با خدمات',onTap:()=>_open(context,Uri.parse(_websiteUri))),
 ]));
}

class _Action extends StatelessWidget{
 const _Action({required this.icon,required this.title,required this.subtitle,this.onTap,this.enabled=true,this.tag});
 final IconData icon;final String title,subtitle;final VoidCallback? onTap;final bool enabled;final String? tag;
 @override Widget build(BuildContext context)=>Card(color:Colors.white,margin:const EdgeInsets.only(bottom:7),child:ListTile(dense:true,minLeadingWidth:30,contentPadding:const EdgeInsets.symmetric(horizontal:12,vertical:1),leading:Icon(icon,color:enabled?const Color(0xFFE30613):const Color(0xFF9CA3AF),size:22),title:Text(title,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w800)),subtitle:Text(subtitle,style:const TextStyle(fontSize:10)),trailing:tag==null?const Icon(Icons.chevron_left,size:18):Text(tag!,style:const TextStyle(fontSize:9,color:Color(0xFF9CA3AF))),onTap:enabled?onTap:null));
}

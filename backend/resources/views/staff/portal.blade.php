<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>پنل پشتیبانی کارگزار</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#f7f7f9;color:#1f2937;font-family:Tahoma,Arial,sans-serif}.top{background:#c62828;color:#fff;padding:16px 22px;display:flex;justify-content:space-between;align-items:center;gap:12px}.top h1{font-size:18px;margin:0}.top form{margin:0}.top button{border:1px solid #ffffff80;background:transparent;color:#fff;border-radius:8px;padding:8px 12px;font:inherit}.wrap{max-width:1200px;margin:22px auto;padding:0 14px;display:grid;grid-template-columns:minmax(260px,360px) 1fr;gap:16px}.box{background:#fff;border:1px solid #e5e7eb;border-radius:14px;overflow:hidden}.head{padding:14px 16px;border-bottom:1px solid #eee;font-weight:bold}.filters{display:flex;gap:8px;padding:10px}.filters a{font-size:12px;text-decoration:none;color:#c62828;border:1px solid #f0b9b9;border-radius:20px;padding:6px 10px}.list{max-height:72vh;overflow:auto}.item{display:block;padding:13px 15px;text-decoration:none;color:inherit;border-bottom:1px solid #f1f1f1}.item.active{background:#fff3f3}.item strong{display:block;font-size:13px}.item small{display:block;color:#64748b;margin-top:5px;line-height:1.6}.conversation{min-height:70vh;display:flex;flex-direction:column}.messages{padding:18px;flex:1;overflow:auto;max-height:58vh}.msg{max-width:78%;padding:10px 13px;margin:0 0 10px;border-radius:12px;font-size:13px;line-height:1.8;white-space:pre-wrap}.customer{background:#fce8e8;margin-left:auto}.staff{background:#f1f5f9;margin-right:auto}.assistant{background:#f4effa;margin-right:auto;border:1px solid #e5d9f2}.compose{border-top:1px solid #eee;padding:14px;display:flex;gap:8px}.compose textarea{flex:1;min-height:46px;max-height:110px;border:1px solid #ddd;border-radius:10px;padding:10px;font:inherit}.btn{border:0;background:#c62828;color:#fff;border-radius:10px;padding:10px 16px;font:inherit;cursor:pointer}.status{padding:0 16px 12px;display:flex;gap:8px;align-items:center}.empty{padding:30px;text-align:center;color:#64748b;font-size:13px}.pagination{padding:12px;font-size:12px}@media(max-width:760px){.wrap{grid-template-columns:1fr}.list{max-height:35vh}.conversation{min-height:50vh}.messages{max-height:38vh}}
</style>
</head>
<body>
<header class="top"><h1>پنل پشتیبانی کارگزار</h1><form method="post" action="{{ route('staff.portal.logout') }}">@csrf<button>خروج</button></form></header>
<main class="wrap">
<section class="box">
<div class="head">گفت‌وگوها</div>
<nav class="filters"><a href="{{ route('staff.portal.index',['status'=>'open']) }}">باز</a><a href="{{ route('staff.portal.index',['status'=>'closed']) }}">بسته</a><a href="{{ route('staff.portal.index',['status'=>'all']) }}">همه</a></nav>
<div class="list">
@forelse($conversations as $conversation)
<a class="item {{ $selected?->id===$conversation->id?'active':'' }}" href="{{ route('staff.portal.show',$conversation->id) }}">
<strong>{{ $conversation->customer?->full_name ?: $conversation->customer?->mobile ?: 'مهمان اپلیکیشن' }}</strong>
<small>{{ $conversation->status==='open'?'باز':'بسته' }} · {{ $conversation->messages_count }} پیام · {{ $conversation->last_message_at?->format('Y/m/d H:i') }}</small>
</a>
@empty<div class="empty">گفت‌وگویی برای نمایش وجود ندارد.</div>@endforelse
</div>
<div class="pagination">{{ $conversations->links() }}</div>
</section>
<section class="box conversation">
@if($selected)
<div class="head">گفت‌وگو #{{ $selected->id }} — {{ $selected->customer?->mobile ?: 'کاربر مهمان' }}</div>
<div class="status">
<span>وضعیت: {{ $selected->status==='open'?'باز':'بسته' }}</span>
<form method="post" action="{{ route('staff.portal.status',$selected->id) }}">@csrf @method('PATCH')
<input type="hidden" name="status" value="{{ $selected->status==='open'?'closed':'open' }}">
<button class="btn" type="submit">{{ $selected->status==='open'?'بستن گفت‌وگو':'بازگشایی' }}</button>
</form>
</div>
<div class="messages" id="messages" data-last-id="{{ $messages->last()?->id ?? 0 }}">
@forelse($messages as $message)
<div class="msg {{ $message->sender_type==='customer'?'customer':($message->sender_type==='assistant'?'assistant':'staff') }}">{{ $message->body }}</div>
@empty<div class="empty">هنوز پیامی ثبت نشده است.</div>@endforelse
</div>
@if($selected->status==='open')
<form class="compose" method="post" action="{{ route('staff.portal.reply',$selected->id) }}">@csrf
<textarea name="body" required maxlength="2000" placeholder="پاسخ کارشناس..."></textarea><button class="btn" type="submit">ارسال پاسخ</button>
</form>
@endif
@else
<div class="empty" style="margin:auto">برای مشاهده پیام‌ها، یک گفت‌وگو را از فهرست انتخاب کنید.</div>
@endif
</section>
</main>
<script>
const box=document.getElementById('messages');
if(box){
  box.scrollTop=box.scrollHeight;
  const conversationId=@json($selected?->id);
  let messageCount=box.querySelectorAll('.msg').length;
  async function refreshMessages(){
    try{
      const response=await fetch('/staff/portal/conversations/'+conversationId+'/messages',{headers:{Accept:'application/json'}});
      if(!response.ok)return;
      const payload=await response.json();
      const messages=payload.data||[];
      if(messages.length<=messageCount)return;
      const nearBottom=box.scrollTop+box.clientHeight>=box.scrollHeight-24;
      box.replaceChildren();
      for(const message of messages){
        const item=document.createElement('div');
        item.className='msg '+(message.sender_type==='customer'?'customer':'staff');
        item.textContent=message.body||'';
        box.appendChild(item);
      }
      messageCount=messages.length;
      box.dataset.lastId=messages.length?messages[messages.length-1].id:box.dataset.lastId;
      if(nearBottom)box.scrollTop=box.scrollHeight;
    }catch(_){}
  }
  window.setInterval(refreshMessages,5000);
}
</script>
</body></html>

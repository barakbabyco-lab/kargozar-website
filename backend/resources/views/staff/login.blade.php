<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>ورود کارشناسان | کارگزار</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#f7f7f9;color:#1f2937;font-family:Tahoma,Arial,sans-serif;display:grid;min-height:100vh;place-items:center;padding:20px}.panel{width:min(420px,100%);background:#fff;border:1px solid #eee;border-radius:18px;padding:28px;box-shadow:0 12px 40px #0000000a}h1{font-size:20px;margin:0 0 8px}.muted{color:#64748b;font-size:13px;line-height:1.8}label{display:block;margin:18px 0 7px;font-size:13px}input{width:100%;padding:13px;border:1px solid #ddd;border-radius:10px;font:inherit}button{width:100%;margin-top:20px;padding:13px;border:0;border-radius:10px;background:#c62828;color:#fff;font:inherit;font-weight:bold;cursor:pointer}.error{color:#b91c1c;font-size:12px;margin-top:6px}
</style>
</head>
<body><main class="panel">
<h1>پنل پشتیبانی کارگزار</h1><p class="muted">ورود کارشناسان و مدیران پشتیبانی</p>
<form method="post" action="{{ route('staff.portal.authenticate') }}">
@csrf
<label for="email">ایمیل سازمانی</label><input id="email" name="email" type="email" autocomplete="username" required value="{{ old('email') }}">
@error('email')<div class="error">{{ $message }}</div>@enderror
<label for="password">گذرواژه</label><input id="password" name="password" type="password" autocomplete="current-password" required>
<button type="submit">ورود به پنل</button>
</form></main></body></html>

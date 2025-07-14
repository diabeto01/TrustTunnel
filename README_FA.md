## Trust Tunnel چیست؟

Trust Tunnel یک تونل معکوس (Reverse Tunnel) امن، پایدار و سریع است که بر پایه‌ی پروتکل **QUIC** (از طریق UDP/TCP) طراحی شده است.

---

## 🚀 نحوه اجرا

برای راه‌اندازی، اسکریپت **main.sh** را روی سرور خود (Debian یا Ubuntu) اجرا کنید:
```
bash <(curl -Ls https://raw.githubusercontent.com/Erfan-XRay/TrustTunnel/main/main.sh)
```
اسکریپت main.sh از فایل‌های کمکی داخل پوشه lib استفاده می‌کند و تنها نقطهٔ ورود برنامه است. این ساختار ماژولار باعث می‌شود main.sh کوتاه بماند و هر قابلیت به صورت مستقل قابل به‌روزرسانی باشد.
### ماژول‌های موجود در `lib/`
- `colors.sh` و `utils.sh` برای توابع عمومی
- `logs.sh` و `validation.sh`
- `scheduler.sh` و `setup.sh`
- `install.sh` برای نصب وابستگی‌ها
- `reverse.sh` و `direct.sh` برای حالت‌های سرور
- `certificates.sh` برای مدیریت TLS
- `menu.sh` پیاده‌ساز منوی تعاملی

اسکریپت‌های قدیمی `alpha.sh` و `beta.sh` حذف شده‌اند؛ کافی‌ست `main.sh` را اجرا کنید.

---
## آموزش استفاده
[![Watch the video](https://img.youtube.com/vi/mwQJ4_pYLNc/hqdefault.jpg)](https://youtu.be/mwQJ4_pYLNc)
## ⚙️ امکانات

- افزودن، حذف و مدیریت سرویس‌های کلاینت/سرور  
- مشاهده لاگ‌های هر کلاینت به‌صورت جداگانه  
- رابط کاربری تعاملی با محیط رنگی و زیبا  
- قابلیت اتصال و هماهنگی آسان با ابزارهایی مثل Xray، V2Ray، WireGuard و...

---

## 📣 سوشیال مدیای من


[![Telegram](https://img.shields.io/badge/Telegram--0088CC?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/Erfan_XRay) 
[![YouTube](https://img.shields.io/badge/YouTube--FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/@Erfan_XRay/videos)

---

## 💰 لینک حمایت مالی

<a href="https://nowpayments.io/donation?api_key=HHZTHS8-YC9MEHG-HTC73AH-5WVP950" target="_blank" rel="noreferrer noopener">
    <img src="https://nowpayments.io/images/embeds/donation-button-white.svg" alt="Cryptocurrency & Bitcoin donation button by NOWPayments">
</a>

🙏 از حمایت شما بسیار سپاسگزاریم!

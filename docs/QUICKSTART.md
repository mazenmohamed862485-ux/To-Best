# TO Best — دليل البدء السريع (QUICKSTART.md)

## ⚡ في 5 دقائق

### 1. متطلبات البيئة

```bash
# تثبيت Flutter (إذا لم يكن مثبتاً)
# https://docs.flutter.dev/get-started/install

# التحقق من البيئة
flutter doctor

# المطلوب:
# ✓ Flutter (Channel stable, 3.22.x+)
# ✓ Android toolchain - develop for Android devices
# ✓ Android Studio (optional) أو VS Code + Flutter extension
```

---

### 2. استنساخ المشروع

```bash
git clone https://github.com/YOUR_ORG/to_best.git
cd to_best
```

---

### 3. تثبيت المكتبات

```bash
flutter pub get
```

---

### 4. إعداد الاتصال بالسيرفر

أنشئ ملف `assets/config.json` أو أدخل البيانات عبر الواجهة:

```bash
# الطريقة الأسهل: عبر التطبيق مباشرة
# 1. شغّل التطبيق
# 2. الإعدادات → Google Sheets → أدخل URL + Secret Key
```

أو أضف البيانات في الكود مؤقتاً للتطوير (للاختبار فقط):
```dart
// lib/core/constants/app_constants.dart
// أضف قيم افتراضية للتطوير
static const String devWebAppUrl = 'https://script.google.com/macros/s/YOUR_URL/exec';
static const String devSecretKey  = 'YOUR_SECRET_KEY';
```

---

### 5. تشغيل التطبيق

```bash
# التشغيل على جهاز Android متصل أو محاكي
flutter run

# تشغيل مع تمكين الـ verbose log
flutter run -v

# اختيار جهاز محدد
flutter devices          # عرض الأجهزة المتاحة
flutter run -d DEVICE_ID
```

---

### 6. بناء APK للاختبار

```bash
# APK debug (سريع، بدون توقيع)
flutter build apk --debug
# المخرج: build/app/outputs/flutter-apk/app-debug.apk

# APK release (يحتاج keystore)
flutter build apk --release --split-per-abi
```

---

### 7. حساب الأدمن الافتراضي (offline)

```
Email:    admin@local
Password: admin123
```

> هذا الحساب يعمل بدون إنترنت وبدون إعداد السيرفر، للاختبار المحلي فقط.

---

## 🗂 هيكل المشروع السريع

```
lib/
├── main.dart              ← نقطة البداية
├── core/
│   ├── l10n/              ← النصوص AR + EN
│   ├── network/           ← API + Sync + Connectivity
│   ├── storage/           ← SQLite + SecureStorage
│   ├── theme/             ← الألوان + الثيم
│   └── providers/         ← Riverpod providers مشتركة
└── features/
    ├── auth/              ← تسجيل الدخول والتسجيل
    ├── home/              ← الشاشة الرئيسية
    ├── workout/           ← التمارين
    ├── nutrition/         ← التغذية
    ├── attendance/        ← الحضور
    ├── progress/          ← التقدم
    ├── chat/              ← الشات
    ├── admin/             ← لوحة الإدارة
    └── settings/          ← الإعدادات
```

---

## 🔧 أوامر مفيدة

```bash
# تحليل الكود
flutter analyze

# تشغيل الاختبارات
flutter test

# تنظيف build cache
flutter clean && flutter pub get

# إعادة توليد Riverpod code (إذا استخدمت @riverpod annotations)
dart run build_runner build --delete-conflicting-outputs

# رؤية شجرة الـ widgets في الـ DevTools
flutter run --debug
# ثم: أدوات Flutter DevTools → Widget Inspector

# تحليل حجم APK
flutter build apk --analyze-size

# Hot reload (أثناء التشغيل)
# اضغط r في الـ terminal

# Hot restart (أثناء التشغيل)
# اضغط R في الـ terminal
```

---

## 🌍 إضافة لغة جديدة

1. افتح `lib/core/l10n/app_localizations.dart`
2. أضف `Map` جديدة للغة (مثل `_fr` للفرنسية)
3. عدّل `isSupported` لتشمل الـ locale الجديدة
4. أضف `Locale('fr')` لقائمة `supportedLocales` في `main.dart`

---

## 🎨 تغيير الألوان

```dart
// lib/core/theme/app_colors.dart
static const Color primaryGreen = Color(0xFF4CAF50); // ← غيّر هنا
```

---

## ➕ إضافة شاشة جديدة

```bash
# 1. أنشئ الملف
touch lib/features/FEATURE_NAME/screens/new_screen.dart

# 2. أضف Route في main_shell.dart أو AppRouter
# 3. أضف Provider إذا لزم في features/FEATURE_NAME/providers/
# 4. أضف نصوص في app_localizations.dart
```

---

## 🐛 حل مشاكل شائعة

| المشكلة | الحل |
|---------|------|
| `Flutter SDK not found` | تأكد من `flutter` في الـ PATH |
| `Gradle build failed` | `flutter clean && flutter pub get` |
| `minSdk too low` | تأكد `minSdk = 21` في `build.gradle` |
| `Keystore not found` | أنشئ `keystore.jks` أولاً (انظر DEPLOY.md) |
| `API call returns null` | تحقق من URL و Secret Key في الإعدادات |
| `Fonts not showing` | تأكد من وجود الخطوط في `assets/fonts/` و `pubspec.yaml` |
| `RTL not working` | تأكد من `Directionality` في `main.dart` |
| `SQLite error` | نفّذ `flutter clean` وأعد تثبيت التطبيق |

---

## 📱 تثبيت APK يدوياً على الجهاز

```bash
# توصيل الجهاز وتفعيل USB Debugging
adb devices                    # تأكد أن الجهاز ظاهر
adb install app-release.apk   # تثبيت
adb logcat | grep "to_best"   # مراقبة logs
```

---

## 🔑 إعداد Google Apps Script (GAS)

1. افتح [script.google.com](https://script.google.com)
2. أنشئ مشروعاً جديداً
3. ارفع ملف `apps-script/Code.gs` من المشروع الأصلي
4. انشر كـ WebApp:
   - Execute as: **Me**
   - Who has access: **Anyone**
5. انسخ الـ URL ← ضعه في إعدادات التطبيق
6. في الكود، عيّن `SECRET_KEY` ← ضعه في إعدادات التطبيق

---

## 📊 متطلبات الأصول (Assets)

```
assets/
├── images/
│   ├── logo_dark.png      # 512×512 px - للثيم الداكن
│   └── logo_light.png     # 512×512 px - للثيم الفاتح
└── fonts/
    ├── Cairo-Regular.ttf
    ├── Cairo-SemiBold.ttf
    ├── Cairo-Bold.ttf
    ├── Inter-Regular.ttf
    ├── Inter-SemiBold.ttf
    └── Inter-Bold.ttf
```

> الخطوط تحتاج تحميل يدوي من Google Fonts:
> - [Cairo](https://fonts.google.com/specimen/Cairo)
> - [Inter](https://fonts.google.com/specimen/Inter)

# TO Best — دليل النشر والتثبيت (DEPLOY.md)

## 1. المتطلبات الأساسية

```bash
# Flutter SDK (stable)
flutter --version   # يجب أن يكون 3.22.0+

# Java JDK 17
java -version

# Android SDK
# تأكد أن ANDROID_HOME أو ANDROID_SDK_ROOT مضبوط

# Gradle (يُحمَّل تلقائياً)
```

---

## 2. إعداد التوقيع (Keystore)

### إنشاء Keystore جديد
```bash
keytool -genkey -v \
  -keystore android/app/keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias tobest_key
```

### إنشاء ملف key.properties
```bash
# android/key.properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=tobest_key
storeFile=keystore.jks
```

> ⚠️ **تحذير**: لا تضع `key.properties` و `keystore.jks` في Git.
> أضف هذا السطر لـ `.gitignore`:
> ```
> android/key.properties
> android/app/keystore.jks
> ```

---

## 3. بناء APK

### APK منفصل حسب المعمارية (موصى به)
```bash
flutter build apk \
  --release \
  --target-platform android-arm,android-arm64,android-x64 \
  --split-per-abi
```

**المخرجات:**
```
build/app/outputs/flutter-apk/
├── app-arm64-v8a-release.apk    # أجهزة 64-bit (الأغلبية)
├── app-armeabi-v7a-release.apk  # أجهزة 32-bit قديمة
└── app-x86_64-release.apk       # محاكيات
```

### APK موحد (Fat APK)
```bash
flutter build apk --release
# المخرج: build/app/outputs/flutter-apk/app-release.apk
```

---

## 4. بناء AAB (Play Store)

```bash
flutter build appbundle --release
# المخرج: build/app/outputs/bundle/release/app-release.aab
```

> AAB هو الصيغة المطلوبة لرفع التطبيق على Google Play.

---

## 5. التحقق من التوقيع

```bash
# التحقق من APK
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk

# معلومات التوقيع
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

---

## 6. إعدادات الإصدار (Version)

**الملف:** `pubspec.yaml`
```yaml
version: 1.0.0+1
#         ^^^^^  VersionName (ما يراه المستخدم)
#               ^ VersionCode (رقم داخلي يجب رفعه مع كل إصدار)
```

### رفع الإصدار
```bash
# مثال: رفع VersionCode يدوياً
# pubspec.yaml: version: 1.2.0+5
```

---

## 7. النشر عبر Codemagic

### الإعداد الأول
1. اذهب إلى [codemagic.io](https://codemagic.io)
2. اربط مستودع GitHub/GitLab
3. أضف المتغيرات البيئية (Environment Variables):

| المتغير | القيمة |
|---------|--------|
| `CM_KEYSTORE` | محتوى `keystore.jks` مُحوَّل لـ Base64 |
| `CM_KEYSTORE_PASSWORD` | كلمة مرور الـ keystore |
| `CM_KEY_ALIAS` | اسم الـ key alias |
| `CM_KEY_PASSWORD` | كلمة مرور المفتاح |

### تحويل Keystore إلى Base64
```bash
base64 -i android/app/keystore.jks | pbcopy  # macOS
base64 android/app/keystore.jks              # Linux
```

### تفعيل البناء
- Push إلى `main` → يبني APK تلقائياً
- Push tag → يبني AAB للـ Play Store

---

## 8. النشر على Google Play

1. افتح [Google Play Console](https://play.google.com/console)
2. أنشئ تطبيقاً جديداً (Package: `com.tobest.app`)
3. ارفع `app-release.aab`
4. أكمل بيانات المتجر (وصف، صور، تصنيف)
5. أرسل للمراجعة

---

## 9. الإعداد الأول للتطبيق

بعد التثبيت، يحتاج المستخدم (أو الأدمن) لإعداد الاتصال:

1. افتح التطبيق → إعدادات → إعدادات Google Sheets
2. أدخل **رابط WebApp** (Google Apps Script URL)
3. أدخل **مفتاح الأمان** (Secret Key)
4. اضغط **اختبار الاتصال**
5. إذا نجح الاختبار ← يمكن تسجيل الدخول

---

## 10. ملاحظات مهمة

- **minSdk 21**: يدعم Android 5.0+ (يغطي >98% من الأجهزة)
- **targetSdk 35**: متوافق مع Android 15
- **MultiDex**: مفعّل لدعم المكتبات الكبيرة
- **ProGuard**: مفعّل في release لتقليل الحجم وحماية الكود
- **Cleartext Traffic**: معطَّل (HTTPS فقط) للأمان
- **Network Security Config**: يمنع الاتصالات غير الآمنة

---

## 11. هيكل الإصدارات المقترح

| الفرع | الغرض |
|-------|--------|
| `main` | الإصدار المستقر للإنتاج |
| `develop` | التطوير النشط |
| `feature/xxx` | ميزات جديدة |
| `release/v1.x.x` | إعداد إصدارات |
| `hotfix/xxx` | إصلاحات عاجلة |

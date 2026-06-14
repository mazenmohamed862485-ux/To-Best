# TO Best — توثيق المشروع الشامل

## 1. نظرة عامة

**TO Best** هو تطبيق تدريب ولياقة بدنية احترافي مبني بـ Flutter، يوفر:

- إدارة برامج التمارين ومتابعة الجلسات
- تتبع التغذية والسعرات الحرارية
- نظام حضور وغياب شهري
- متابعة التقدم والأرقام القياسية
- شات جماعي متعدد الغرف
- لوحة إدارة كاملة للأدمن
- دعم كامل للعربية والإنجليزية مع RTL/LTR

---

## 2. البنية التقنية

```
to_best/
├── lib/
│   ├── main.dart                      # نقطة الدخول + AuthGate
│   ├── core/
│   │   ├── constants/app_constants.dart
│   │   ├── l10n/app_localizations.dart  # AR + EN
│   │   ├── network/
│   │   │   ├── api_client.dart         # GAS HTTP client
│   │   │   ├── connectivity_service.dart
│   │   │   └── sync_service.dart       # Offline queue + auto-sync
│   │   ├── providers/app_providers.dart # Riverpod providers
│   │   ├── router/app_router.dart      # GoRouter navigation
│   │   ├── storage/
│   │   │   ├── local_db.dart          # SQLite cache
│   │   │   └── secure_storage.dart    # Encrypted key storage
│   │   └── theme/
│   │       ├── app_colors.dart
│   │       └── app_theme.dart
│   ├── features/
│   │   ├── auth/           # Login, Register, Guest, Pending, Rejected
│   │   ├── home/           # Dashboard, Stats, PRs
│   │   ├── workout/        # Session, Exercise, Rest Timer, History
│   │   ├── nutrition/      # Food Log, Meal Plan, Water Tracker
│   │   ├── attendance/     # Calendar, Mark days, Stats
│   │   ├── progress/       # PRs, Volume Chart, Body Weight
│   │   ├── chat/           # Multi-room chat, Pinned, Reply
│   │   ├── admin/          # Users, Audit, Program Requests, Subs, Bans
│   │   └── settings/       # Theme, Language, Account, Connection
│   └── shared/
│       └── widgets/         # TbButton, TbTextField, TbSnackbar, TbCard…
├── android/
│   ├── app/build.gradle
│   └── app/src/main/AndroidManifest.xml
├── assets/
│   ├── images/             # logo_dark.png, logo_light.png
│   └── fonts/              # Cairo, Inter
├── docs/
│   ├── PROJECT.md          # هذا الملف
│   ├── DEPLOY.md           # النشر والتوقيع
│   └── QUICKSTART.md       # بدء التطوير
└── codemagic.yaml
```

---

## 3. المعمارية

| طبقة | الأداة | الدور |
|------|--------|-------|
| **State** | Flutter Riverpod v2 | إدارة الحالة |
| **Navigation** | GoRouter | التنقل والحماية |
| **Backend** | Google Apps Script (GAS) | قاعدة البيانات والـ API |
| **Local Cache** | SQLite (sqflite) | التخزين المؤقت |
| **Secure Store** | flutter_secure_storage | مفتاح الأمان |
| **Network** | http + connectivity_plus | الطلبات + رصد الاتصال |
| **Sync** | SyncService (custom) | مزامنة تلقائية + queue |

---

## 4. البيانات والمزامنة

### مصدر البيانات الأساسي
السيرفر (Google Apps Script / Google Sheets) هو **المصدر الوحيد للحقيقة**.

### آلية العمل Offline-First
```
User action
    ↓
Save to SQLite (instant UI update)
    ↓
Add to sync_queue
    ↓
If online → flush queue to GAS API
If offline → queue waits
    ↓
Auto-sync every 30s or on reconnect
```

### جداول SQLite
| الجدول | الغرض |
|--------|--------|
| `settings` | إعدادات التطبيق (URL, language, theme) |
| `users` | بيانات المستخدمين (cache) |
| `workout_logs` | سجلات التمارين |
| `nutrition_logs` | سجلات التغذية |
| `attendance` | الحضور والغياب |
| `messages` | رسائل الشات (cache) |
| `progress` | قياسات التقدم |
| `sync_queue` | طابور المزامنة |
| `kv_store` | بيانات عامة key-value |

---

## 5. شاشات التطبيق

### شاشات المستخدم العادي
| الشاشة | الوصف |
|--------|--------|
| LoginScreen | دخول + تسجيل + ضيف |
| ForgotPasswordScreen | استعادة كلمة المرور |
| GuestLoginScreen | دخول بكود الضيف |
| PendingScreen | انتظار موافقة المدرب |
| RejectedScreen | حساب مرفوض |
| HomeScreen | لوحة رئيسية + تحية + إحصائيات |
| WorkoutScreen | تمرين اليوم + سجل الجلسات |
| ExerciseCard | بطاقة تمرين + مجاميع + وزن + RPE |
| SessionDoneScreen | ملخص الجلسة بعد الانتهاء |
| NutritionScreen | سعرات + وجبات + ماء |
| FoodSearchScreen | بحث في قاعدة الأطعمة |
| MealPlanScreen | خطة الوجبات |
| WaterTrackerScreen | تتبع الماء |
| AttendanceScreen | تقويم الحضور والغياب |
| ProgressScreen | الأرقام القياسية + رسوم بيانية |
| ChatScreen | شات متعدد الغرف |
| SettingsScreen | جميع الإعدادات |
| SetupScreen | إعداد رابط GAS + مفتاح الأمان |

### شاشات الإدارة (Admin / Super Admin فقط)
| الشاشة | الوصف |
|--------|--------|
| AdminScreen | لوحة إدارة كاملة |
| Users Tab | قائمة المستخدمين + بحث + فلترة |
| User Card | موافقة / رفض / تعديل / حذف |
| AuditLogTab | سجل جميع التعديلات |
| ProgramRequestsTab | طلبات تغيير البرنامج |
| SubscriptionRequestsTab | طلبات الاشتراك والدفع |
| BanManagementTab | إدارة المحظورين (super admin) |

---

## 6. الأدوار والصلاحيات

| الدور | الصلاحية |
|-------|----------|
| `trainee` | تمارين + تغذية + شات + ملف شخصي |
| `viewer` | مشاهدة فقط |
| `coach` | كل وظائف trainee + رؤية بيانات الطلاب |
| `admin` | لوحة الإدارة + إدارة المستخدمين |
| `superadmin` | كل صلاحيات admin + حظر + force logout |

---

## 7. الخدمات الخارجية

| الخدمة | الاستخدام |
|---------|----------|
| **Google Apps Script** | Backend API + Google Sheets database |
| **Google Drive** | روابط مقاطع فيديو التمارين |
| **flutter_secure_storage** | تشفير مفتاح الأمان |

---

## 8. اللغة والاتجاه

- **عربية** → `locale: Locale('ar')` + `TextDirection.rtl` + خط Cairo
- **إنجليزية** → `locale: Locale('en')` + `TextDirection.ltr` + خط Inter
- التبديل يتم من الإعدادات ويُطبَّق فوراً بدون إعادة تشغيل
- كل النصوص في `AppLocalizations` (AR + EN)

---

## 9. الهوية البصرية

| العنصر | القيمة |
|--------|--------|
| اللون الأساسي | `#4CAF50` (أخضر) |
| ثيم داكن | خلفية `#0A0A0A` |
| ثيم فاتح | خلفية `#F5F5F5` |
| خط عربي | Cairo |
| خط إنجليزي | Inter |
| الشعار الداكن | `assets/images/logo_dark.png` |
| الشعار الفاتح | `assets/images/logo_light.png` |

---

## 10. متطلبات التشغيل

- Flutter SDK 3.22+
- Dart SDK 3.0+
- Android minSdk 21 (Android 5+)
- Java 17
- Google Apps Script WebApp منشور (URL + Secret Key)

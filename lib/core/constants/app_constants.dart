// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  static const String appName = 'TO Best';
  static const String appVersion = 'v8.2.0';
  static const String packageName = 'com.tobest.app';

  // Development defaults
  static const String devWebAppUrl = 'https://script.google.com/macros/s/AKfycbwQrKSMoGJfnyrUG9zmqd_ou-TqDGyDYcky_WAbZaXrpWA-9JfnNOZLOi33w0q2TYdq/exec';
  static const String devSecretKey = 'Mazen124261';

  // Storage keys
  static const String keyWebAppUrl = 'webAppUrl';
  static const String keySecretKey = 'secretKey';
  static const String keySessionToken = 'sessionToken';
  static const String keyLanguage = 'mc_lang';
  static const String keyTheme = 'mc_theme';
  static const String keyAccentColor = 'mc_accent';
  static const String keyHandMode = 'mc_hand';
  static const String keyCurrentUser = 'mc_user';
  static const String keyForceLogoutPrefix = 'force_logout_seen_';
  static const String keyProfilePicPrefix = 'kv:profile_pic_';
  static const String keyProfilePicUrlPrefix = 'kv:profile_pic_url_';
  static const String keyBannedIdentities = 'kv:banned_identities';

  // Network
  static const int apiTimeoutMs = 14000;
  static const int autoSyncIntervalMs = 30000;
  static const int chatPollIntervalMs = 8000;

  // User roles
  static const String roleTrainee = 'trainee';
  static const String roleViewer = 'viewer';
  static const String roleCoach = 'coach';
  static const String roleAdmin = 'admin';
  static const String roleSuperAdmin = 'superadmin';

  // User statuses
  static const String statusActive = 'active';
  static const String statusPending = 'pending';
  static const String statusRejected = 'rejected';
  static const String statusInactive = 'inactive';
  static const String statusPaymentPending = 'payment_pending';

  // Training programs
  static const String progUL = 'UL';
  static const String progAP = 'AP';
  static const String progFB = 'FB';
  static const String progArnold = 'ARNOLD';
  static const String progPPL = 'PPL';
  static const String progCustom = 'CUSTOM';

  // Attendance marks
  static const String markGym = 'gym';
  static const String markAbsent = 'absent';
  static const String markRest = 'rest';

  // Meal types
  static const String mealBreakfast = 'breakfast';
  static const String mealLunch = 'lunch';
  static const String mealDinner = 'dinner';
  static const String mealSnack = 'snack';

  // Chat rooms
  static const String roomGeneral = 'general';
  static const String roomCoach = 'coach';
  static const String roomAnnouncements = 'announcements';
  static const String roomSupport = 'support';

  // Evaluation labels
  static const String evS1 = 's1';
  static const String evS2 = 's2';
  static const String evS3 = 's3';
  static const String evRV = 'rv';
  static const String evGD = 'gd';
  static const String evST = 'st';
  static const String evWS = 'ws';
  static const String evDN = 'dn';
  static const String evBeg = 'beg';

  // DB tables
  static const String tableUsers = 'users';
  static const String tableWorkoutLogs = 'workout_logs';
  static const String tableNutritionLogs = 'nutrition_logs';
  static const String tableAttendance = 'attendance';
  static const String tableMessages = 'messages';
  static const String tableSyncQueue = 'sync_queue';
  static const String tableSettings = 'settings';
  static const String tableProgress = 'progress';
  static const String tableSubscriptions = 'subscriptions';

  // Max values
  static const int maxProfilePicSizeBytes = 2 * 1024 * 1024; // 2MB
  static const int maxMessageLength = 1000;
  static const double maxWaterGoalLiters = 6.0;
  static const double minWaterGoalLiters = 0.5;
}

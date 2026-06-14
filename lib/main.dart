// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/providers/app_providers.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/home/screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  runApp(const ProviderScope(child: ToBestApp()));
}

class ToBestApp extends ConsumerWidget {
  const ToBestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePref = ref.watch(themeProvider);
    final langPref = ref.watch(languageProvider);
    final isArabic = langPref == 'ar';
    final isDark = themePref == 'dark';

    return MaterialApp(
      title: 'TO Best',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(isArabic: isArabic),
      darkTheme: AppTheme.dark(isArabic: isArabic),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(langPref),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection:
              isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      home: const _AppGate(),
    );
  }
}

// ── Auth Gate ─────────────────────────────────────────────────
class _AppGate extends ConsumerWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: _resolveScreen(authState),
    );
  }

  Widget _resolveScreen(AuthState authState) {
    switch (authState.status) {
      case AuthStatus.loading:
        return const _SplashView();

      case AuthStatus.unauthenticated:
        return const LoginScreen();

      case AuthStatus.authenticated:
        return const MainShell();

      case AuthStatus.pending:
        return const PendingScreen();

      case AuthStatus.rejected:
        return const RejectedScreen();

      case AuthStatus.paymentPending:
        return const _PaymentPendingView();

      case AuthStatus.subscriptionExpired:
        return const _SubscriptionExpiredView();

      case AuthStatus.deviceBlocked:
        return const _DeviceBlockedView();
    }
  }
}

// ── Splash ────────────────────────────────────────────────────
class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.3), width: 2),
              ),
              child: const Icon(Icons.fitness_center,
                  size: 56, color: AppColors.primaryGreen),
            ),
            const SizedBox(height: 24),
            const Text(
              'TO Best',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                  letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            const Text(
              'نظام التدريب والتغذية الاحترافي',
              style: TextStyle(
                  fontSize: 14, color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: AppColors.primaryGreen,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Payment Pending ───────────────────────────────────────────
class _PaymentPendingView extends ConsumerWidget {
  const _PaymentPendingView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.payment_outlined,
                  size: 80, color: AppColors.warning),
              const SizedBox(height: 24),
              const Text('في انتظار تأكيد الدفع',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text(
                  'تم استلام طلبك، سيتم مراجعة عملية الدفع خلال 24 ساعة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.darkTextSecondary)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(authProvider.notifier).logout(),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('تسجيل الخروج'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Subscription Expired ──────────────────────────────────────
class _SubscriptionExpiredView extends ConsumerWidget {
  const _SubscriptionExpiredView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_off_outlined,
                  size: 80, color: AppColors.error),
              const SizedBox(height: 24),
              const Text('انتهى اشتراكك',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text('يرجى التواصل مع المدرب لتجديد اشتراكك.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.darkTextSecondary)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('🔄 تجديد الاشتراك'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(authProvider.notifier).logout(),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('تسجيل الخروج'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Device Blocked ────────────────────────────────────────────
class _DeviceBlockedView extends ConsumerWidget {
  const _DeviceBlockedView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phonelink_lock_outlined,
                  size: 80, color: AppColors.error),
              const SizedBox(height: 24),
              const Text('هذا الجهاز محظور',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text('تواصل مع المدرب لإلغاء الحظر.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.darkTextSecondary)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(authProvider.notifier).logout(),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('تسجيل الخروج'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

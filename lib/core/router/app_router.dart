// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/home/screens/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState.status == AuthStatus.authenticated;
      final isPending = authState.status == AuthStatus.pending;
      final isRejected = authState.status == AuthStatus.rejected;
      final isLoading = authState.status == AuthStatus.loading;
      final isPaymentPending = authState.status == AuthStatus.paymentPending;
      final isSubExpired = authState.status == AuthStatus.subscriptionExpired;

      if (isLoading) return '/splash';
      if (!isAuth && state.matchedLocation != '/login' &&
          state.matchedLocation != '/setup') return '/login';
      if (isPending && state.matchedLocation != '/pending') return '/pending';
      if (isRejected && state.matchedLocation != '/rejected') return '/rejected';
      if (isPaymentPending && state.matchedLocation != '/payment-pending') {
        return '/payment-pending';
      }
      if (isSubExpired && state.matchedLocation != '/subscription-expired') {
        return '/subscription-expired';
      }
      if (isAuth && state.matchedLocation == '/login') return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (_, __) => const SetupScreen(),
      ),
      GoRoute(
        path: '/pending',
        builder: (_, __) => const PendingScreen(),
      ),
      GoRoute(
        path: '/rejected',
        builder: (_, __) => const RejectedScreen(),
      ),
      GoRoute(
        path: '/payment-pending',
        builder: (_, __) => const _PaymentPendingScreen(),
      ),
      GoRoute(
        path: '/subscription-expired',
        builder: (_, __) => const _SubscriptionExpiredScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const MainShell(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryGreen),
            SizedBox(height: 24),
            Text('TO Best', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen)),
          ],
        ),
      ),
    );
  }
}

class _PaymentPendingScreen extends ConsumerWidget {
  const _PaymentPendingScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.payment, size: 80, color: AppColors.warning),
              const SizedBox(height: 24),
              const Text('في انتظار تأكيد الدفع',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text('سيتم مراجعة طلبك خلال 24 ساعة',
                  textAlign: TextAlign.center),
              const SizedBox(height: 40),
              OutlinedButton(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionExpiredScreen extends ConsumerWidget {
  const _SubscriptionExpiredScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.subscriptions_outlined,
                  size: 80, color: AppColors.error),
              const SizedBox(height: 24),
              const Text('انتهى اشتراكك',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Text('يرجى تجديد الاشتراك للاستمرار',
                  textAlign: TextAlign.center),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen),
                child: const Text('🔄 تجديد الاشتراك'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

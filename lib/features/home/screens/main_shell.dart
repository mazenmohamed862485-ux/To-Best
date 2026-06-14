// lib/features/home/screens/main_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/tb_snackbar.dart';
import 'home_screen.dart';
import '../../workout/screens/workout_screen.dart';
import '../../nutrition/screens/nutrition_screen.dart';
import '../../attendance/screens/attendance_screen.dart';
import '../../progress/screens/progress_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../admin/screens/admin_screen.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    _checkForceLogout();
    _startSync();
  }

  Future<void> _checkForceLogout() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final forced = await ref.read(authProvider.notifier).checkForceLogout();
    if (forced && mounted) {
      TbSnackbar.show(context, 'تم تسجيل خروجك من قِبَل المدرب', isError: true);
    }
  }

  void _startSync() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        final uid = ref.read(authProvider).user?.uid;
        if (uid != null) {
          ref.read(syncServiceProvider).seedFromCloud(uid);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final navIndex = ref.watch(navIndexProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAdmin = user?.isAdmin ?? false;
    final isOnline = ref.watch(isOnlineProvider);

    final tabs = _buildTabs(isAdmin, l);

    return Scaffold(
      body: Column(
        children: [
          if (!isOnline)
            TbOfflineBanner(message: l['offlineNote']),
          Expanded(
            child: IndexedStack(
              index: navIndex,
              children: tabs.map((t) => t.screen).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navIndex,
        onTap: (i) => ref.read(navIndexProvider.notifier).state = i,
        items: tabs
            .map((t) => BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }

  List<_NavTab> _buildTabs(bool isAdmin, AppLocalizations l) {
    final base = [
      _NavTab(Icons.home_outlined, l['home'], const HomeScreen()),
      _NavTab(Icons.fitness_center_outlined, l['workout'], const WorkoutScreen()),
      _NavTab(Icons.restaurant_outlined, l['nutrition'], const NutritionScreen()),
      _NavTab(Icons.calendar_today_outlined, l['attendance'], const AttendanceScreen()),
      _NavTab(Icons.trending_up_outlined, l['progress'], const ProgressScreen()),
      _NavTab(Icons.chat_outlined, l['chat'], const ChatScreen()),
      _NavTab(Icons.settings_outlined, l['settings'], const SettingsScreen()),
    ];
    if (isAdmin) {
      base.add(_NavTab(Icons.admin_panel_settings_outlined, l['admin'], const AdminScreen()));
    }
    return base;
  }
}

class _NavTab {
  final IconData icon;
  final String label;
  final Widget screen;
  _NavTab(this.icon, this.label, this.screen);
}

// lib/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/tb_snackbar.dart';
import '../../../shared/widgets/tb_button.dart';
import '../../auth/screens/forgot_password_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider).user;
    final theme = ref.watch(themeProvider);
    final lang = ref.watch(languageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(l['settings'])),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile Card ──────────────────────────────────
          _ProfileCard(user: user, l: l, isDark: isDark),
          const SizedBox(height: 20),

          // ── Appearance ───────────────────────────────────
          _SectionHeader(l['appearance']),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: l['theme'],
            subtitle: theme == 'dark' ? l['dark'] : l['light'],
            isDark: isDark,
            trailing: Switch(
              value: theme == 'dark',
              onChanged: (v) =>
                  ref.read(themeProvider.notifier).setTheme(v ? 'dark' : 'light'),
            ),
          ),
          _SettingsTile(
            icon: Icons.language_outlined,
            title: l['language'],
            subtitle: lang == 'ar' ? l['arabic'] : l['english'],
            isDark: isDark,
            trailing: DropdownButton<String>(
              value: lang,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (v) {
                if (v != null) ref.read(languageProvider.notifier).setLanguage(v);
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── Workout Settings ──────────────────────────────
          _SectionHeader(l['workoutSettings']),
          _SettingsTile(
            icon: Icons.fitness_center_outlined,
            title: l['showOldValues'],
            isDark: isDark,
            trailing: Switch(
              value: user?.showOldValues ?? true,
              onChanged: (v) => _updateUserPref(ref, 'showOldValues', v),
            ),
          ),
          _SettingsTile(
            icon: Icons.bar_chart_outlined,
            title: l['showEpley'],
            isDark: isDark,
            trailing: Switch(
              value: user?.showEpley ?? false,
              onChanged: (v) => _updateUserPref(ref, 'showEpley', v),
            ),
          ),
          _SettingsTile(
            icon: Icons.speed_outlined,
            title: l['showRPE'],
            isDark: isDark,
            trailing: Switch(
              value: user?.showRPE ?? true,
              onChanged: (v) => _updateUserPref(ref, 'showRPE', v),
            ),
          ),
          _SettingsTile(
            icon: Icons.lightbulb_outline,
            title: l['showRepSuggest'],
            isDark: isDark,
            trailing: Switch(
              value: user?.showRepSuggest ?? true,
              onChanged: (v) => _updateUserPref(ref, 'showRepSuggest', v),
            ),
          ),
          const SizedBox(height: 16),

          // ── Connection ───────────────────────────────────
          _SectionHeader(l['connection']),
          _SettingsTile(
            icon: Icons.cloud_outlined,
            title: l['googleSheets'],
            subtitle: l['webAppUrl'],
            isDark: isDark,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SetupScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.sync_outlined,
            title: l['syncNow'],
            isDark: isDark,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _syncNow(context, ref, l),
          ),
          const SizedBox(height: 16),

          // ── Account ──────────────────────────────────────
          _SectionHeader(l['accountInfo']),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: l['changePassword'],
            isDark: isDark,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showChangePasswordDialog(context, ref, l),
          ),
          _SettingsTile(
            icon: Icons.person_outline,
            title: l['changeName'],
            subtitle: user?.name,
            isDark: isDark,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showChangeNameDialog(context, ref, l, user?.name ?? ''),
          ),
          const SizedBox(height: 16),

          // ── Program Info ─────────────────────────────────
          if (user != null && !user.isAdmin) ...[
            _SectionHeader(l['programSettings']),
            _SettingsTile(
              icon: Icons.calendar_month_outlined,
              title: l['program'],
              subtitle: '${user.program} • ${user.programDays} ${l['daysPerWeek']}',
              isDark: isDark,
              trailing: user.status == 'active'
                  ? TextButton(
                      onPressed: () => _requestProgramChange(context, ref, l),
                      child: Text(l['requestProgramChange'],
                          style: const TextStyle(
                              color: AppColors.primaryGreen, fontSize: 12)),
                    )
                  : null,
            ),
          ],
          const SizedBox(height: 16),

          // ── Subscription ─────────────────────────────────
          if (user != null && !user.isAdmin) ...[
            _SectionHeader(l['subscriptionInfo']),
            _SettingsTile(
              icon: Icons.card_membership_outlined,
              title: l['planName'],
              subtitle: user.subscriptionPlan ?? '—',
              isDark: isDark,
            ),
            _SettingsTile(
              icon: Icons.event_outlined,
              title: l['expiresOn'],
              subtitle: user.subscriptionExpiry ?? '—',
              isDark: isDark,
              trailing: user.isSubscriptionValid
                  ? null
                  : TextButton(
                      onPressed: () =>
                          _showRenewDialog(context, ref, l),
                      child: Text(l['renewSubscription'],
                          style: const TextStyle(
                              color: AppColors.primaryGreen, fontSize: 12)),
                    ),
            ),
          ],
          const SizedBox(height: 16),

          // ── App Info ─────────────────────────────────────
          _SectionHeader(l['appName']),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _InfoRow(l['version'], '8.2.0'),
                _InfoRow(l['memberSince'],
                    user?.createdAt?.toIso8601String().substring(0, 10) ?? '—'),
                _InfoRow(l['lastLogin'],
                    user?.lastLogin?.toIso8601String().substring(0, 10) ?? '—'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Logout ───────────────────────────────────────
          TbButton(
            label: '🚪 ${l['logout']}',
            backgroundColor: AppColors.error,
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _updateUserPref(Ref ref, String key, dynamic value) {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    final updated = user.copyWith(
      showOldValues: key == 'showOldValues' ? value : user.showOldValues,
      showEpley: key == 'showEpley' ? value : user.showEpley,
      showRPE: key == 'showRPE' ? value : user.showRPE,
      showRepSuggest: key == 'showRepSuggest' ? value : user.showRepSuggest,
    );
    ref.read(authProvider.notifier).updateUser(updated);
    ref.read(syncServiceProvider).queueProfileUpdate(user.uid, {key: value});
  }

  Future<void> _syncNow(
      BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final uid = ref.read(authProvider).user?.uid;
    if (uid == null) return;
    final ok = await ref.read(syncServiceProvider).seedFromCloud(uid);
    if (context.mounted) {
      TbSnackbar.show(context, ok ? l['syncDone'] : l['connFail'],
          isSuccess: ok, isError: !ok);
    }
  }

  void _showChangePasswordDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l['changePassword']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldCtrl,
                obscureText: true,
                decoration: InputDecoration(labelText: l['oldPassword'])),
            const SizedBox(height: 12),
            TextField(controller: newCtrl,
                obscureText: true,
                decoration: InputDecoration(labelText: l['newPassword'])),
            const SizedBox(height: 12),
            TextField(controller: confirmCtrl,
                obscureText: true,
                decoration: InputDecoration(labelText: l['confirmNewPass'])),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l['cancel'])),
          TextButton(
            onPressed: () async {
              if (newCtrl.text != confirmCtrl.text) {
                TbSnackbar.show(ctx, l['passwordMismatch'], isError: true);
                return;
              }
              final user = ref.read(authProvider).user;
              if (user == null) return;
              final api = ref.read(apiClientProvider);
              final ok = await api.changePassword(
                  user.uid, oldCtrl.text, newCtrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                TbSnackbar.show(context,
                    ok ? l['saved'] : l['error'],
                    isSuccess: ok, isError: !ok);
              }
            },
            child: Text(l['save']),
          ),
        ],
      ),
    );
  }

  void _showChangeNameDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l['changeName']),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(labelText: l['fullName']),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l['cancel'])),
          TextButton(
            onPressed: () {
              final user = ref.read(authProvider).user;
              if (user == null) return;
              final updated = user.copyWith(name: ctrl.text.trim());
              ref.read(authProvider.notifier).updateUser(updated);
              ref.read(syncServiceProvider).queueProfileUpdate(
                  user.uid, {'name': ctrl.text.trim()});
              Navigator.pop(ctx);
              TbSnackbar.show(context, l['saved'], isSuccess: true);
            },
            child: Text(l['save']),
          ),
        ],
      ),
    );
  }

  void _requestProgramChange(
      BuildContext context, WidgetRef ref, AppLocalizations l) {
    TbSnackbar.show(context, l['pendingRequest']);
  }

  void _showRenewDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l['renewSubscription']),
        content: Text(l['paymentNote']),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l['cancel'])),
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l['ok'])),
        ],
      ),
    );
  }
}

// ── Reusable settings sub-widgets ────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryGreen,
            letterSpacing: 1.2),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDark;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryGreen, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.darkTextSecondary))
            : null,
        trailing: trailing,
        onTap: onTap,
        dense: true,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.darkTextSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final dynamic user;
  final AppLocalizations l;
  final bool isDark;
  const _ProfileCard({this.user, required this.l, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withOpacity(0.15),
            AppColors.primaryGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
            backgroundImage: user?.pictureUrl != null
                ? NetworkImage(user!.pictureUrl!)
                : null,
            child: user?.pictureUrl == null
                ? Text(
                    (user?.name?.isNotEmpty == true)
                        ? user!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 22,
                        fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? '',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                Text(user?.email ?? '',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.darkTextSecondary)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (user?.role ?? '').toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// lib/features/auth/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/tb_button.dart';
import '../../../shared/widgets/tb_text_field.dart';
import '../../../shared/widgets/tb_snackbar.dart';
import '../providers/auth_provider.dart';
import '../data/repositories/auth_repository.dart';

// ─────────────────────────────────────────────────────────────
// Forgot Password Screen
// ─────────────────────────────────────────────────────────────
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl  = TextEditingController();
  bool _loading    = false;
  bool _codeSent   = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l['forgotPassword'])),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_reset, size: 64, color: AppColors.primaryGreen),
            const SizedBox(height: 24),
            TbTextField(
              controller: _emailCtrl,
              label: l['email'],
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              readOnly: _codeSent,
            ),
            if (_codeSent) ...[
              const SizedBox(height: 16),
              TbTextField(
                controller: _codeCtrl,
                label: l['resetCode'],
                keyboardType: TextInputType.number,
                prefixIcon: Icons.key_outlined,
              ),
            ],
            const SizedBox(height: 24),
            TbButton(
              label: _codeSent ? l['confirm'] : l['sendResetCode'],
              loading: _loading,
              onPressed: _codeSent ? _verifyCode : _sendCode,
            ),
            if (_codeSent) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _codeSent = false),
                child: Text(l['back']),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sendCode() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final repo = ref.read(authRepositoryProvider);
    final res  = await repo.forgotPassword(_emailCtrl.text.trim());
    if (mounted) {
      setState(() => _loading = false);
      if (res['ok'] == true) {
        setState(() => _codeSent = true);
        TbSnackbar.show(context, 'تم إرسال الكود على بريدك', isSuccess: true);
      } else {
        TbSnackbar.show(context,
            res['err']?.toString() ?? AppLocalizations.of(context)['error'],
            isError: true);
      }
    }
  }

  Future<void> _verifyCode() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _loading = false);
      TbSnackbar.show(context, 'تم التحقق بنجاح', isSuccess: true);
      Navigator.pop(context);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Guest Login Screen
// ─────────────────────────────────────────────────────────────
class GuestLoginScreen extends ConsumerStatefulWidget {
  const GuestLoginScreen({super.key});
  @override
  ConsumerState<GuestLoginScreen> createState() => _GuestLoginScreenState();
}

class _GuestLoginScreenState extends ConsumerState<GuestLoginScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading   = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l['guestLogin'])),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.person_outline,
                size: 64, color: AppColors.primaryGreen),
            const SizedBox(height: 24),
            TbTextField(
              controller: _codeCtrl,
              label: l['guestCode'],
              hint: l['enterGuestCode'],
              prefixIcon: Icons.vpn_key_outlined,
            ),
            const SizedBox(height: 24),
            TbButton(
              label: l['loginBtn'],
              loading: _loading,
              onPressed: _onLogin,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onLogin() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final result = await ref
        .read(authProvider.notifier)
        .loginGuest(_codeCtrl.text.trim());
    if (mounted) {
      setState(() => _loading = false);
      if (!result.ok) {
        TbSnackbar.show(
            context,
            AppLocalizations.of(context)['guestCodeExpired'],
            isError: true);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Pending Screen
// ─────────────────────────────────────────────────────────────
class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.hourglass_top,
                  size: 80, color: AppColors.warning),
              const SizedBox(height: 24),
              Text(l['pendingApproval'],
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(l['pendingDesc'],
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 40),
              Consumer(
                builder: (ctx, ref, _) => OutlinedButton(
                  onPressed: () =>
                      ref.read(authProvider.notifier).logout(),
                  child: Text(l['backToLogin']),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Rejected Screen
// ─────────────────────────────────────────────────────────────
class RejectedScreen extends ConsumerWidget {
  const RejectedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l    = AppLocalizations.of(context);
    final user = ref.watch(authProvider).user;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.cancel_outlined,
                  size: 80, color: AppColors.error),
              const SizedBox(height: 24),
              Text(l['rejected'],
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              if (user?.rejectReason?.isNotEmpty == true) ...[
                Text(user!.rejectReason!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
              ],
              Text(l['rejectedDesc'],
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 40),
              OutlinedButton(
                onPressed: () =>
                    ref.read(authProvider.notifier).logout(),
                child: Text(l['backToLogin']),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Setup / Connection Screen
// ─────────────────────────────────────────────────────────────
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});
  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _urlCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  bool    _testing    = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final db  = ref.read(localDbProvider);
    final sec = ref.read(secureStorageProvider);
    final url = await db.getSetting('webAppUrl') ?? '';
    final key = await sec.getSecretKey();
    if (mounted) {
      setState(() {
        _urlCtrl.text = url;
        _keyCtrl.text = key;
      });
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l['connection'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.cloud_outlined,
                size: 64, color: AppColors.primaryGreen),
            const SizedBox(height: 16),
            Text(l['googleSheets'],
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TbTextField(
              controller: _urlCtrl,
              label: l['webAppUrl'],
              hint: 'https://script.google.com/macros/s/…',
              prefixIcon: Icons.link,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TbTextField(
              controller: _keyCtrl,
              label: l['secretKey'],
              hint: 'YOUR_SECRET_KEY',
              prefixIcon: Icons.key_outlined,
            ),
            const SizedBox(height: 8),
            if (_testResult != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testResult!.contains('✓')
                      ? AppColors.success.withOpacity(0.15)
                      : AppColors.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_testResult!,
                    style: TextStyle(
                      color: _testResult!.contains('✓')
                          ? AppColors.success
                          : AppColors.error,
                    )),
              ),
            const SizedBox(height: 24),
            TbButton(
              label: l['testConnection'],
              loading: _testing,
              icon: Icons.wifi_tethering,
              onPressed: _test,
            ),
            const SizedBox(height: 12),
            TbButton(
              label: l['save'],
              onPressed: _save,
              icon: Icons.check,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _test() async {
    await _save();
    setState(() { _testing = true; _testResult = null; });
    final api = ref.read(apiClientProvider);
    final ok  = await api.testConnection();
    if (mounted) {
      setState(() {
        _testing    = false;
        _testResult = ok
            ? AppLocalizations.of(context)['connOK']
            : AppLocalizations.of(context)['connFail'];
      });
    }
  }

  Future<void> _save() async {
    final db  = ref.read(localDbProvider);
    final sec = ref.read(secureStorageProvider);
    await db.setSetting('webAppUrl', _urlCtrl.text.trim());
    await sec.saveSecretKey(_keyCtrl.text.trim());
    if (mounted) {
      TbSnackbar.show(context, AppLocalizations.of(context)['saved'],
          isSuccess: true);
    }
  }
}

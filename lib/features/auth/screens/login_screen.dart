// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tb_button.dart';
import '../../../shared/widgets/tb_text_field.dart';
import '../../../shared/widgets/tb_snackbar.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  late TabController _tab;
  final _loginFormKey = GlobalKey<FormState>();
  final _regFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  bool _obscureLogin = true;
  bool _obscureReg = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                children: [
                  Image.asset(
                    isDark
                        ? 'assets/images/logo_dark.png'
                        : 'assets/images/logo_light.png',
                    height: 100,
                    errorBuilder: (_, __, ___) => const _LogoFallback(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l['appName'],
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l['tagline'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // ── Tabs ────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCardAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: l['login']),
                  Tab(text: l['register']),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Forms ────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _buildLoginForm(l, theme, isDark),
                  _buildRegisterForm(l, theme, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(AppLocalizations l, ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TbTextField(
              controller: _emailCtrl,
              label: l['email'],
              hint: 'example@email.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (v) {
                if (v == null || v.isEmpty) return l['fieldRequired'];
                if (!v.contains('@')) return l['invalidEmail'];
                return null;
              },
            ),
            const SizedBox(height: 16),
            TbTextField(
              controller: _passCtrl,
              label: l['password'],
              hint: '••••••••',
              obscureText: _obscureLogin,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(_obscureLogin
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureLogin = !_obscureLogin),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return l['fieldRequired'];
                return null;
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen()),
                ),
                child: Text(l['forgotPassword'],
                    style: const TextStyle(color: AppColors.primaryGreen)),
              ),
            ),
            const SizedBox(height: 8),
            TbButton(
              label: l['loginBtn'],
              loading: _loading,
              onPressed: _onLogin,
            ),
            const SizedBox(height: 16),
            Row(children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'أو',
                  style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted),
                ),
              ),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GuestLoginScreen()),
              ),
              icon: const Icon(Icons.person_outline),
              label: Text(l['guestLogin']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm(AppLocalizations l, ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _regFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TbTextField(
              controller: _nameCtrl,
              label: l['fullName'],
              prefixIcon: Icons.person_outline,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l['fieldRequired'] : null,
            ),
            const SizedBox(height: 16),
            TbTextField(
              controller: _phoneCtrl,
              label: l['phone'],
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l['fieldRequired'] : null,
            ),
            const SizedBox(height: 16),
            TbTextField(
              controller: _regEmailCtrl,
              label: l['email'],
              hint: 'example@email.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (v) {
                if (v == null || v.isEmpty) return l['fieldRequired'];
                if (!v.contains('@')) return l['invalidEmail'];
                return null;
              },
            ),
            const SizedBox(height: 16),
            TbTextField(
              controller: _regPassCtrl,
              label: l['password'],
              obscureText: _obscureReg,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(_obscureReg
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureReg = !_obscureReg),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return l['fieldRequired'];
                if (v.length < 6) return l['passwordTooShort'];
                return null;
              },
            ),
            const SizedBox(height: 16),
            TbTextField(
              controller: _regConfirmCtrl,
              label: l['confirmPass'],
              obscureText: _obscureConfirm,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v != _regPassCtrl.text) return l['passwordMismatch'];
                return null;
              },
            ),
            const SizedBox(height: 16),
            TbTextField(
              controller: _referralCtrl,
              label: l['enterReferralCode'],
              prefixIcon: Icons.card_giftcard_outlined,
            ),
            const SizedBox(height: 24),
            TbButton(
              label: l['registerBtn'],
              loading: _loading,
              onPressed: _onRegister,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passCtrl.text,
        );
    if (mounted) {
      setState(() => _loading = false);
      if (!result.ok) {
        TbSnackbar.show(context, _translateError(result.error ?? ''),
            isError: true);
      }
    }
  }

  Future<void> _onRegister() async {
    if (!_regFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await ref.read(authProvider.notifier).register({
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'email': _regEmailCtrl.text.trim().toLowerCase(),
      'password': _regPassCtrl.text,
      'referredBy': _referralCtrl.text.trim(),
    });
    if (mounted) {
      setState(() => _loading = false);
      if (!result.ok) {
        TbSnackbar.show(context, _translateError(result.error ?? ''),
            isError: true);
      }
    }
  }

  String _translateError(String err) {
    final l = AppLocalizations.of(context);
    switch (err) {
      case 'not_configured': return 'التطبيق غير مُعد. تواصل مع المشرف';
      case 'network_error': return l['offline'];
      case 'invalid_credentials': return 'بيانات الدخول غير صحيحة';
      case 'account_banned': return 'هذا الحساب محظور';
      case 'device_blocked': return l['deviceBlocked'];
      case 'email_exists': return 'البريد الإلكتروني مستخدم مسبقاً';
      case 'user_not_found': return 'المستخدم غير موجود';
      default: return l['error'];
    }
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.fitness_center,
        size: 52,
        color: AppColors.primaryGreen,
      ),
    );
  }
}

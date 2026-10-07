import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../common/widgets/widgets.dart';
import '../application/auth_controller.dart';
import '../application/auth_state.dart';

/// Document 7 (#1): first screen. Minimal-click, works one-handed (Doc 24) —
/// two fields and one button. The last email used is remembered on the
/// device, so a returning user only types the password.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _lastEmailKey = 'rmgflow.last_login_email';
  static const _storage = FlutterSecureStorage();

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _rememberEmail = true;

  @override
  void initState() {
    super.initState();
    _loadLastEmail();
  }

  Future<void> _loadLastEmail() async {
    try {
      final email = await _storage.read(key: _lastEmailKey);
      if (!mounted || email == null || email.isEmpty || _emailController.text.isNotEmpty) return;
      setState(() => _emailController.text = email);
      _passwordFocus.requestFocus();
    } catch (_) {
      // Storage unavailable (tests, locked keystore) — just start empty.
    }
  }

  Future<void> _storeEmail(String email) async {
    try {
      if (_rememberEmail) {
        await _storage.write(key: _lastEmailKey, value: email);
      } else {
        await _storage.delete(key: _lastEmailKey);
      }
    } catch (_) {
      // Remembering the email is a convenience only.
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    _storeEmail(email);
    ref.read(authControllerProvider.notifier).login(
          email: email,
          password: _passwordController.text,
          deviceInfo: 'flutter-android',
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;
    final theme = Theme.of(context);
    final s = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _BrandHeader(topInset: MediaQuery.paddingOf(context).top)),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Transform.translate(
                  offset: const Offset(0, -AppSpacing.xxl),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Welcome back',
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: AppSpacing.xxs),
                              Text('Sign in to continue',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
                              const SizedBox(height: AppSpacing.xl),
                              if (authState is AuthError) ...[
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: s.errorContainer,
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline_rounded, color: s.onErrorContainer),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(authState.failure.message,
                                            style: TextStyle(color: s.onErrorContainer)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                              TextFormField(
                                controller: _emailController,
                                enabled: !isLoading,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email, AutofillHints.username],
                                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.alternate_email_rounded),
                                ),
                                validator: (value) =>
                                    (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              TextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                enabled: !isLoading,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                    icon: Icon(
                                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (value) => (value == null || value.isEmpty) ? 'Enter your password' : null,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              CheckboxListTile(
                                value: _rememberEmail,
                                onChanged:
                                    isLoading ? null : (v) => setState(() => _rememberEmail = v ?? _rememberEmail),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                                title: const Text('Remember my email on this device'),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              PrimaryButton(
                                label: 'Sign in',
                                icon: Icons.login_rounded,
                                loading: isLoading,
                                onPressed: _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Text(
                'Sourcing · Costing · Orders · Shipments',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(color: s.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-bleed brand gradient with the app mark, name and tagline.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.topInset});

  final double topInset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl * 1.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -AppSpacing.xxl,
            top: topInset,
            child: Icon(Icons.checkroom_rounded, size: 180, color: Colors.white.withValues(alpha: 0.07)),
          ),
          Positioned(
            left: -AppSpacing.xl,
            bottom: AppSpacing.xxl,
            child: Icon(Icons.local_shipping_rounded, size: 110, color: Colors.white.withValues(alpha: 0.06)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.xl, topInset + AppSpacing.xxxl, AppSpacing.xl, AppSpacing.xxxl + AppSpacing.xxl),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.checkroom_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'RMGFlow',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Bangladesh buying-house operations, in your pocket',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  height: 4,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AppColors.marigold,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
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

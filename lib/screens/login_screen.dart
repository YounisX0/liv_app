import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../theme/liv_theme.dart';
import '../utils/app_validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _AuthMode { login, signup }

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  _AuthMode _mode = _AuthMode.login;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String _selectedRole = 'farmer';

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  bool get _isLogin => _mode == _AuthMode.login;

  Future<void> _submit() async {
    final state = context.read<AppState>();
    final l = AppLocalizations(state.locale);
    state.clearError();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final fullName = AppValidators.normalizeSpaces(_fullNameCtrl.text);

    if (_isLogin) {
      final success = await state.login(
        email: email,
        password: password,
      );

      if (!success && mounted && state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage!)),
        );
      }
      return;
    }

    final signedUp = await state.signup(
      email: email,
      password: password,
      fullName: fullName,
      role: _selectedRole,
    );

    if (!signedUp) {
      if (mounted && state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage!)),
        );
      }
      return;
    }

    final loggedIn = await state.login(
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.t('account_created_login_ok')),
        ),
      );
    } else if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations(state.locale);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              final next = state.locale == AppLocale.en
                                  ? AppLocale.ar
                                  : AppLocale.en;
                              state.setLocale(next);
                            },
                            icon: const Text('🌐'),
                            label: Text(
                              state.locale == AppLocale.en ? 'العربية' : 'English',
                            ),
                          ),
                        ),
                        const Center(
                          child: _BrandLogo(size: 250),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          l.t('brand_title'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: LivTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin ? l.t('login_subtitle') : l.t('signup_subtitle'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : LivTheme.muted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: _ModeButton(
                                label: l.t('login'),
                                selected: _isLogin,
                                onTap: () {
                                  setState(() {
                                    _mode = _AuthMode.login;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ModeButton(
                                label: l.t('sign_up'),
                                selected: !_isLogin,
                                onTap: () {
                                  setState(() {
                                    _mode = _AuthMode.signup;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _fullNameCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l.t('full_name'),
                              prefixIcon: const Icon(Icons.badge_outlined),
                            ),
                            validator: AppValidators.fullName,
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: InputDecoration(
                              labelText: l.t('user_type'),
                              prefixIcon: const Icon(
                                Icons.admin_panel_settings_outlined,
                              ),
                            ),
                            items: [
                              DropdownMenuItem<String>(
                                value: 'farmer',
                                child: Text(l.t('role_farmer')),
                              ),
                              DropdownMenuItem<String>(
                                value: 'veterinarian',
                                child: Text(l.t('role_veterinarian')),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedRole = value);
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: l.t('email'),
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: AppValidators.email,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          textInputAction:
                              _isLogin ? TextInputAction.done : TextInputAction.next,
                          onFieldSubmitted: (_) {
                            if (_isLogin) _submit();
                          },
                          decoration: InputDecoration(
                            labelText: l.t('password'),
                            helperText: _isLogin ? null : l.t('password_hint'),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: _isLogin
                              ? AppValidators.loginPassword
                              : AppValidators.strongPassword,
                        ),
                        if (!_isLogin) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmPasswordCtrl,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: l.t('confirm_password'),
                              prefixIcon: const Icon(Icons.verified_user_outlined),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: (value) => AppValidators.confirmPassword(
                              value,
                              _passwordCtrl.text,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        if (state.errorMessage != null &&
                            state.errorMessage!.trim().isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: LivTheme.danger.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: LivTheme.danger.withOpacity(0.25),
                              ),
                            ),
                            child: Text(
                              state.errorMessage!,
                              style: const TextStyle(
                                color: LivTheme.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: state.isAuthenticating ? null : _submit,
                            icon: state.isAuthenticating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _isLogin
                                        ? Icons.login_rounded
                                        : Icons.person_add_alt_1_rounded,
                                  ),
                            label: Text(
                              state.isAuthenticating
                                  ? (_isLogin
                                      ? l.t('signing_in')
                                      : l.t('creating_account'))
                                  : (_isLogin ? l.t('login') : l.t('create_account')),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.t('welcome_back'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : LivTheme.muted,
                            fontSize: 12,
                          ),
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
    );
  }
}

class _BrandLogo extends StatelessWidget {
  final double size;
  const _BrandLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset(
        'assets/images/LIVLogo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [LivTheme.primary, LivTheme.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(size * 0.28),
            ),
            child: const Center(
              child: Icon(
                Icons.agriculture_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? LivTheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? LivTheme.primary
                  : LivTheme.primary.withOpacity(0.20),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : LivTheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
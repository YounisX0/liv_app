import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../theme/liv_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _AuthMode { login, signup }

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _fullNameCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  _AuthMode _mode = _AuthMode.login;
  bool _obscurePassword = true;

  String _selectedRole = 'farmer';

  final List<Map<String, String>> _roles = const [
    {'value': 'farmer', 'label': 'Farmer'},
    {'value': 'veterinarian', 'label': 'Veterinarian'},
    {'value': 'admin', 'label': 'Admin'},
  ];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _fullNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();
    state.clearError();

    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final fullName = _fullNameCtrl.text.trim();

    if (_mode == _AuthMode.signup) {
      final signedUp = await state.signup(
        email: email,
        password: password,
        fullName: fullName,
        role: _selectedRole,
      );

      if (!signedUp || !mounted) return;

      final loggedIn = await state.login(
        email: email,
        password: password,
      );

      if (!loggedIn || !mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created and logged in successfully.'),
        ),
      );
      return;
    }

    final loggedIn = await state.login(
      email: email,
      password: password,
    );

    if (!loggedIn || !mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isLogin = _mode == _AuthMode.login;

    return Scaffold(
      backgroundColor: LivTheme.bg,
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
                              state.locale == AppLocale.en
                                  ? 'العربية'
                                  : 'English',
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [LivTheme.primary, LivTheme.accent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Text(
                                'L',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'LIV Smart Farm',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: LivTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isLogin
                              ? 'Sign in to access your farm dashboard.'
                              : 'Create a new account for the LIV dashboard.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: LivTheme.muted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 22),

                        Row(
                          children: [
                            Expanded(
                              child: _ModeButton(
                                label: 'Login',
                                selected: isLogin,
                                onTap: () => setState(() => _mode = _AuthMode.login),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ModeButton(
                                label: 'Sign up',
                                selected: !isLogin,
                                onTap: () => setState(() => _mode = _AuthMode.signup),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        if (!isLogin) ...[
                          TextFormField(
                            controller: _fullNameCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Full name',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (_mode == _AuthMode.signup &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Please enter your full name.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: InputDecoration(
                              labelText: 'User type',
                              prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _roles
                                .map(
                                  (role) => DropdownMenuItem<String>(
                                    value: role['value'],
                                    child: Text(role['label']!),
                                  ),
                                )
                                .toList(),
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
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            final v = (value ?? '').trim();
                            if (v.isEmpty) return 'Please enter your email.';
                            if (!v.contains('@')) return 'Please enter a valid email.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
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
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            final v = value ?? '';
                            if (v.isEmpty) return 'Please enter your password.';
                            if (_mode == _AuthMode.signup && v.length < 4) {
                              return 'Password must be at least 4 characters.';
                            }
                            return null;
                          },
                        ),
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
                                    isLogin
                                        ? Icons.login_rounded
                                        : Icons.person_add_alt_1_rounded,
                                  ),
                            label: Text(
                              state.isAuthenticating
                                  ? (isLogin ? 'Signing in...' : 'Creating account...')
                                  : (isLogin ? 'Login' : 'Create account'),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: LivTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          'Backend connected through saved app settings.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: LivTheme.muted,
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
      color: selected ? LivTheme.primary : Colors.white,
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
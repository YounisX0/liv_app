import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../theme/liv_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _confirmPasswordCtrl;

  String? _loadedUserId;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _confirmPasswordCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _syncFromUser(AppState state) {
    final user = state.currentUser;
    if (user == null) return;
    if (_loadedUserId == user.userId) return;

    _loadedUserId = user.userId;
    _fullNameCtrl.text = user.fullName;
    _emailCtrl.text = user.email;
  }

  Future<void> _saveAccount() async {
    final state = context.read<AppState>();
    final l = AppLocalizations(state.locale);

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _localError = null;
    });

    final password = _passwordCtrl.text.trim();
    final ok = await state.updateMyAccount(
      fullName: _fullNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: password.isEmpty ? null : password,
    );

    if (!mounted) return;

    if (ok) {
      _passwordCtrl.clear();
      _confirmPasswordCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.t('account_updated_ok'))),
      );
      return;
    }

    setState(() {
      _localError = state.profileUpdateError ?? l.t('account_update_failed');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations(state.locale);
    final isDark = state.isDarkMode;
    final user = state.currentUser;
    _syncFromUser(state);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: l.t('language'),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ChoiceCard(
                      label: 'English',
                      subtitle: 'EN',
                      leading: '🇬🇧',
                      selected: state.locale == AppLocale.en,
                      onTap: () => state.setLocale(AppLocale.en),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ChoiceCard(
                      label: 'العربية',
                      subtitle: 'AR',
                      leading: '🇸🇦',
                      selected: state.locale == AppLocale.ar,
                      onTap: () => state.setLocale(AppLocale.ar),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: l.t('appearance'),
            children: [
              SwitchListTile.adaptive(
                value: isDark,
                onChanged: (value) {
                  state.setDarkMode(value);
                },
                title: Text(l.t('dark_mode')),
                subtitle: Text(
                  isDark ? l.t('dark_mode_desc_on') : l.t('dark_mode_desc_off'),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: l.t('my_account'),
            children: [
              if (user != null) ...[
                _InfoRow(
                  label: l.t('role'),
                  value: _roleLabel(l, user.role),
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  label: l.t('farm'),
                  value: user.farmId,
                ),
                const SizedBox(height: 14),
              ],
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _fullNameCtrl,
                      decoration: InputDecoration(
                        labelText: l.t('full_name'),
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return l.t('full_name_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l.t('email'),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final email = (value ?? '').trim();
                        if (email.isEmpty) {
                          return l.t('email_required');
                        }
                        final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
                        if (!ok) {
                          return l.t('email_invalid');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l.t('new_password_optional'),
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) return null;
                        if (text.length < 8) {
                          return l.t('password_min_8');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l.t('confirm_new_password'),
                        prefixIcon: const Icon(Icons.verified_user_outlined),
                      ),
                      validator: (value) {
                        if (_passwordCtrl.text.trim().isEmpty &&
                            (value ?? '').trim().isEmpty) {
                          return null;
                        }
                        if ((value ?? '').trim() != _passwordCtrl.text.trim()) {
                          return l.t('passwords_do_not_match');
                        }
                        return null;
                      },
                    ),
                    if (((_localError ?? state.profileUpdateError) ?? '')
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          (_localError ?? state.profileUpdateError)!,
                          style: const TextStyle(
                            color: LivTheme.danger,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: state.isUpdatingProfile ? null : _saveAccount,
                        icon: state.isUpdatingProfile
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          state.isUpdatingProfile
                              ? l.t('saving')
                              : l.t('save_changes'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _roleLabel(AppLocalizations l, String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return l.t('role_admin');
      case 'veterinarian':
        return l.t('role_veterinarian');
      default:
        return l.t('role_farmer');
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: LivTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final String leading;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.label,
    required this.subtitle,
    required this.leading,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? LivTheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? LivTheme.primary
                  : LivTheme.primary.withOpacity(0.20),
            ),
          ),
          child: Column(
            children: [
              Text(
                leading,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : LivTheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: selected ? Colors.white70 : LivTheme.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: LivTheme.muted,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: LivTheme.text,
          ),
        ),
      ],
    );
  }
}
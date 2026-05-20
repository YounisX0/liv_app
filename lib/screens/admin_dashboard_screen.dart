import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/api_models.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/liv_theme.dart';
import '../utils/app_validators.dart';
import '../widgets/widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshLiveData();
    });
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

  String? _validateRequired(
    String? value,
    String fieldLabel,
    AppLocalizations l,
  ) {
    if ((value ?? '').trim().isEmpty) {
      return l.t('required_field').replaceAll('{field}', fieldLabel);
    }
    return null;
  }

  String? _validateEmail(
    String? value,
    AppLocalizations l,
  ) {
    final email = (value ?? '').trim();
    if (email.isEmpty) {
      return l.t('required_field').replaceAll('{field}', l.t('email'));
    }
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!ok) return l.t('email_invalid');
    return null;
  }

  String? _validatePassword(
    String? value,
    AppLocalizations l, {
    required bool requiredPassword,
  }) {
    final password = (value ?? '').trim();

    if (!requiredPassword && password.isEmpty) return null;
    if (requiredPassword && password.isEmpty) {
      return l.t('required_field').replaceAll('{field}', l.t('password'));
    }

    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);

    if (password.length < 8 || !hasLetter || !hasDigit) {
      return l.t('password_strength_admin');
    }
    return null;
  }

  String? _validatePositiveInt(
    String? value,
    String fieldLabel,
    AppLocalizations l,
  ) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return l.t('required_field').replaceAll('{field}', fieldLabel);
    }
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 0) {
      return l.t('invalid_positive_number').replaceAll('{field}', fieldLabel);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations(state.locale);
    final overview = state.adminOverview;

    final recentAlerts = [...state.alerts]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final topAlerts = recentAlerts.take(6).toList();

    return RefreshIndicator(
      onRefresh: () => context.read<AppState>().refreshLiveData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.adminErrorMessage != null &&
              state.adminErrorMessage!.trim().isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LivTheme.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LivTheme.danger.withOpacity(0.25)),
              ),
              child: Text(
                state.adminErrorMessage!,
                style: const TextStyle(
                  color: LivTheme.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (state.isAdminLoading || state.isFetchingData)
            const LinearProgressIndicator(),
          if (state.isAdminLoading || state.isFetchingData)
            const SizedBox(height: 12),
          Text(
            l.t('admin_overview_title'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: LivTheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.t('admin_overview_subtitle'),
            style: const TextStyle(
              color: LivTheme.muted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.15,
            children: [
              KpiCard(
                label: l.t('total_users'),
                value: '${overview?.totalUsers ?? 0}',
                hint: l.t('registered_accounts'),
                valueColor: LivTheme.primary,
              ),
              KpiCard(
                label: l.t('total_cows'),
                value: '${overview?.totalCows ?? 0}',
                hint: l.t('managed_livestock'),
                valueColor: LivTheme.accent,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _AdminSectionHeaderPlain(
            title: l.t('recent_alerts_title'),
          ),
          const SizedBox(height: 8),
          if (topAlerts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: LivTheme.ok),
                    const SizedBox(width: 10),
                    Expanded(child: Text(l.t('no_alerts_at_moment'))),
                  ],
                ),
              ),
            ),
          ...topAlerts.map(
            (alert) => _AdminAlertCard(
              alert: alert,
              cows: state.cows,
              l: l,
            ),
          ),
          const SizedBox(height: 24),
          _AdminSectionHeader(
            title: l.t('users_title'),
            actionLabel: l.t('add_user'),
            onAction: () => _showUserDialog(context),
          ),
          const SizedBox(height: 8),
          _UsersTable(
            users: state.adminUsers,
            currentUserId: state.currentUser?.userId,
            onEdit: (user) => _showUserDialog(context, user: user),
            onDelete: (user) => _confirmDeleteUser(context, user),
            l: l,
            roleLabelBuilder: _roleLabel,
          ),
          const SizedBox(height: 24),
          _AdminSectionHeader(
            title: l.t('cows_title'),
            actionLabel: l.t('add_cow'),
            onAction: () => _showCowDialog(context),
          ),
          const SizedBox(height: 8),
          _CowsTable(
            cows: state.adminCows,
            onEdit: (cow) => _showCowDialog(context, cow: cow),
            onDelete: (cow) => _confirmDeleteCow(context, cow),
            l: l,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showUserDialog(
    BuildContext context, {
    ApiUser? user,
  }) async {
    final state = context.read<AppState>();
    final l = AppLocalizations(state.locale);
    final isEdit = user != null;

    final formKey = GlobalKey<FormState>();

    final fullNameCtrl = TextEditingController(text: user?.fullName ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final passwordCtrl = TextEditingController();
    final farmIdCtrl = TextEditingController(text: user?.farmId ?? 'farm1');

    String role = user?.role ?? 'farmer';
    bool obscurePassword = true;

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return AlertDialog(
              title: Text(isEdit ? l.t('edit_user') : l.t('add_user')),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: fullNameCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l.t('full_name'),
                          ),
                          validator: (value) =>
                              _validateRequired(value, l.t('full_name'), l),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l.t('email'),
                          ),
                          validator: (value) => _validateEmail(value, l),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordCtrl,
                          obscureText: obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: isEdit
                                ? l.t('password_optional_keep')
                                : l.t('password'),
                            helperText: isEdit
                                ? l.t('password_optional_helper')
                                : l.t('password_hint'),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setLocalState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => _validatePassword(
                            value,
                            l,
                            requiredPassword: !isEdit,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: farmIdCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l.t('farm_id'),
                          ),
                          validator: (value) =>
                              _validateRequired(value, l.t('farm_id'), l),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: role,
                          decoration: InputDecoration(
                            labelText: l.t('role'),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'farmer',
                              child: Text(l.t('role_farmer')),
                            ),
                            DropdownMenuItem(
                              value: 'veterinarian',
                              child: Text(l.t('role_veterinarian')),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text(l.t('role_admin')),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setLocalState(() => role = value);
                            }
                          },
                          validator: (value) =>
                              _validateRequired(value, l.t('role'), l),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l.t('cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    final valid = formKey.currentState?.validate() ?? false;
                    if (!valid) return;
                    Navigator.pop(ctx, true);
                  },
                  child: Text(isEdit ? l.t('save') : l.t('create')),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSubmit != true) return;

    bool success;
    if (isEdit) {
      final updates = <String, dynamic>{
        'fullName': AppValidators.normalizeSpaces(fullNameCtrl.text),
        'email': emailCtrl.text.trim(),
        'farmId': farmIdCtrl.text.trim(),
        'role': role,
      };

      if (passwordCtrl.text.trim().isNotEmpty) {
        updates['password'] = passwordCtrl.text.trim();
      }

      success = await state.adminUpdateUser(
        userId: user.userId,
        updates: updates,
      );
    } else {
      success = await state.adminCreateUser(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
        fullName: AppValidators.normalizeSpaces(fullNameCtrl.text),
        farmId: farmIdCtrl.text.trim(),
        role: role,
      );
    }

    if (!mounted) return;

    if (success) {
      _showSuccess(
        isEdit ? l.t('user_updated_success') : l.t('user_added_success'),
      );
    } else if (state.adminErrorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.adminErrorMessage!)),
      );
    }
  }

  Future<void> _showCowDialog(
    BuildContext context, {
    ApiCow? cow,
  }) async {
    final state = context.read<AppState>();
    final l = AppLocalizations(state.locale);
    final isEdit = cow != null;

    final formKey = GlobalKey<FormState>();

    final cowIdCtrl = TextEditingController(text: cow?.cowId ?? '');
    final nameCtrl = TextEditingController(text: cow?.name ?? '');
    final tagNumberCtrl = TextEditingController(text: cow?.tagNumber ?? '');
    final breedCtrl = TextEditingController(text: cow?.breed ?? '');
    final ageMonthsCtrl =
        TextEditingController(text: cow != null ? '${cow.ageMonths}' : '');
    final deviceIdCtrl = TextEditingController(text: cow?.deviceId ?? '');
    final farmIdCtrl = TextEditingController(text: cow?.farmId ?? 'farm1');

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isEdit ? l.t('edit_cow') : l.t('add_cow')),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: cowIdCtrl,
                      readOnly: isEdit,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l.t('cow_id'),
                      ),
                      validator: (value) =>
                          _validateRequired(value, l.t('cow_id'), l),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l.t('name'),
                      ),
                      validator: (value) =>
                          _validateRequired(value, l.t('name'), l),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: tagNumberCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l.t('tag_number'),
                      ),
                      validator: (value) =>
                          _validateRequired(value, l.t('tag_number'), l),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: breedCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l.t('breed'),
                      ),
                      validator: (value) =>
                          _validateRequired(value, l.t('breed'), l),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: ageMonthsCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l.t('age_months'),
                      ),
                      validator: (value) =>
                          _validatePositiveInt(value, l.t('age_months'), l),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: deviceIdCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l.t('device_id'),
                      ),
                      validator: (value) =>
                          _validateRequired(value, l.t('device_id'), l),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: farmIdCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: l.t('farm_id'),
                      ),
                      validator: (value) =>
                          _validateRequired(value, l.t('farm_id'), l),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.t('cancel')),
            ),
            FilledButton(
              onPressed: () {
                final valid = formKey.currentState?.validate() ?? false;
                if (!valid) return;
                Navigator.pop(ctx, true);
              },
              child: Text(isEdit ? l.t('save') : l.t('create')),
            ),
          ],
        );
      },
    );

    if (shouldSubmit != true) return;

    bool success;
    if (isEdit) {
      success = await state.adminUpdateCow(
        cowId: cow.cowId,
        updates: {
          'name': AppValidators.normalizeSpaces(nameCtrl.text),
          'tagNumber': tagNumberCtrl.text.trim(),
          'breed': breedCtrl.text.trim(),
          'ageMonths': int.parse(ageMonthsCtrl.text.trim()),
          'deviceId': deviceIdCtrl.text.trim(),
          'farmId': farmIdCtrl.text.trim(),
        },
      );
    } else {
      success = await state.adminCreateCow(
        cowId: cowIdCtrl.text.trim(),
        farmId: farmIdCtrl.text.trim(),
        name: AppValidators.normalizeSpaces(nameCtrl.text),
        tagNumber: tagNumberCtrl.text.trim(),
        breed: breedCtrl.text.trim(),
        ageMonths: int.parse(ageMonthsCtrl.text.trim()),
        deviceId: deviceIdCtrl.text.trim(),
      );
    }

    if (!mounted) return;

    if (success) {
      _showSuccess(
        isEdit ? l.t('cow_updated_success') : l.t('cow_added_success'),
      );
    } else if (state.adminErrorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.adminErrorMessage!)),
      );
    }
  }

  Future<void> _confirmDeleteUser(
    BuildContext context,
    ApiUser user,
  ) async {
    final state = context.read<AppState>();
    final l = AppLocalizations(state.locale);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.t('delete_user_confirm_title')),
        content: Text(
          l.t('delete_user_confirm_body').replaceAll('{name}', user.fullName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.t('delete')),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final success = await state.adminDeleteUser(user.userId);
    if (!mounted) return;

    if (success) {
      _showSuccess(l.t('user_deleted_success'));
    } else if (state.adminErrorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.adminErrorMessage!)),
      );
    }
  }

  Future<void> _confirmDeleteCow(
    BuildContext context,
    ApiCow cow,
  ) async {
    final state = context.read<AppState>();
    final l = AppLocalizations(state.locale);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.t('delete_cow_confirm_title')),
        content: Text(
          l.t('delete_cow_confirm_body').replaceAll('{name}', cow.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.t('delete')),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final success = await state.adminDeleteCow(cow.cowId);
    if (!mounted) return;

    if (success) {
      _showSuccess(l.t('cow_deleted_success'));
    } else if (state.adminErrorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.adminErrorMessage!)),
      );
    }
  }
}

class _AdminSectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _AdminSectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: LivTheme.primary,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class _AdminSectionHeaderPlain extends StatelessWidget {
  final String title;

  const _AdminSectionHeaderPlain({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: LivTheme.primary,
      ),
    );
  }
}

class _AdminAlertCard extends StatelessWidget {
  final FarmAlert alert;
  final List<Cow> cows;
  final AppLocalizations l;

  const _AdminAlertCard({
    required this.alert,
    required this.cows,
    required this.l,
  });

  String _statusLabel(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'fever') return l.t('status_fever');
    if (v == 'heat stress') return l.t('status_heat_stress');
    if (v == 'low spo2') return l.t('status_low_spo2');
    if (v == 'healthy') return l.t('status_healthy');
    return raw;
  }

  String _localizedTitle() {
    final raw = alert.title.trim();
    if (raw.toLowerCase().endsWith(' detected')) {
      final status = raw.substring(0, raw.length - ' detected'.length).trim();
      return l
          .t('alert_detected_with_status')
          .replaceAll('{status}', _statusLabel(status));
    }
    return raw;
  }

  String _localizedDetails(String cowName) {
    final raw = alert.details.trim();
    final lower = raw.toLowerCase();

    if (lower.startsWith('latest readings indicate ') && lower.endsWith('.')) {
      final middle = raw.substring(
        'Latest readings indicate '.length,
        raw.length - 1,
      );
      final splitToken = ' for ';
      final idx = middle.lastIndexOf(splitToken);
      if (idx != -1) {
        final status = middle.substring(0, idx).trim();
        final name = middle.substring(idx + splitToken.length).trim();
        return l
            .t('alert_latest_readings_status_for_name')
            .replaceAll('{status}', _statusLabel(status))
            .replaceAll('{name}', name.isEmpty ? cowName : name);
      }
    }

    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final cow = cows.where((c) => c.id == alert.cowId).firstOrNull;
    final cowName = cow?.name ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AlertIcon(alert.severity),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _localizedTitle(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (cow != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      cow.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: LivTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _localizedDetails(cowName),
                    style: const TextStyle(
                      fontSize: 12,
                      color: LivTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersTable extends StatelessWidget {
  final List<ApiUser> users;
  final String? currentUserId;
  final ValueChanged<ApiUser> onEdit;
  final ValueChanged<ApiUser> onDelete;
  final AppLocalizations l;
  final String Function(AppLocalizations l, String role) roleLabelBuilder;

  const _UsersTable({
    required this.users,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
    required this.l,
    required this.roleLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l.t('no_users_found')),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        child: DataTable(
          columns: [
            DataColumn(label: Text(l.t('full_name'))),
            DataColumn(label: Text(l.t('email'))),
            DataColumn(label: Text(l.t('role'))),
            DataColumn(label: Text(l.t('farm'))),
            DataColumn(label: Text(l.t('created'))),
            DataColumn(label: Text(l.t('actions'))),
          ],
          rows: users.map((user) {
            final isSelf = currentUserId == user.userId;
            return DataRow(
              cells: [
                DataCell(Text(user.fullName)),
                DataCell(Text(user.email)),
                DataCell(Text(roleLabelBuilder(l, user.role))),
                DataCell(Text(user.farmId)),
                DataCell(Text(user.createdAt.isEmpty ? '--' : user.createdAt)),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        tooltip: l.t('edit'),
                        onPressed: () => onEdit(user),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: isSelf
                            ? l.t('cannot_delete_yourself')
                            : l.t('delete'),
                        onPressed: isSelf ? null : () => onDelete(user),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CowsTable extends StatelessWidget {
  final List<ApiCow> cows;
  final ValueChanged<ApiCow> onEdit;
  final ValueChanged<ApiCow> onDelete;
  final AppLocalizations l;

  const _CowsTable({
    required this.cows,
    required this.onEdit,
    required this.onDelete,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    if (cows.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l.t('no_cows_found')),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        child: DataTable(
          columns: [
            DataColumn(label: Text(l.t('cow_id'))),
            DataColumn(label: Text(l.t('name'))),
            DataColumn(label: Text(l.t('tag'))),
            DataColumn(label: Text(l.t('breed'))),
            DataColumn(label: Text(l.t('age'))),
            DataColumn(label: Text(l.t('farm'))),
            DataColumn(label: Text(l.t('device_id'))),
            DataColumn(label: Text(l.t('actions'))),
          ],
          rows: cows.map((cow) {
            return DataRow(
              cells: [
                DataCell(Text(cow.cowId)),
                DataCell(Text(cow.name)),
                DataCell(Text(cow.tagNumber)),
                DataCell(Text(cow.breed)),
                DataCell(Text('${cow.ageMonths}')),
                DataCell(Text(cow.farmId)),
                DataCell(Text(cow.deviceId)),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        tooltip: l.t('edit'),
                        onPressed: () => onEdit(cow),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: l.t('delete'),
                        onPressed: () => onDelete(cow),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
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

          const Text(
            'Admin Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: LivTheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage users and cows across the whole system.',
            style: TextStyle(
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
                label: 'Total users',
                value: '${overview?.totalUsers ?? 0}',
                hint: 'Registered accounts',
                valueColor: LivTheme.primary,
              ),
              KpiCard(
                label: 'Total cows',
                value: '${overview?.totalCows ?? 0}',
                hint: 'Managed livestock',
                valueColor: LivTheme.accent,
              ),
            ],
          ),

          const SizedBox(height: 20),

          const _AdminSectionHeaderPlain(
            title: 'Recent Alerts',
          ),
          const SizedBox(height: 8),
          if (topAlerts.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: LivTheme.ok),
                    SizedBox(width: 10),
                    Text('No alerts at the moment.'),
                  ],
                ),
              ),
            ),
          ...topAlerts.map(
            (alert) => _AdminAlertCard(
              alert: alert,
              cows: state.cows,
            ),
          ),

          const SizedBox(height: 24),

          _AdminSectionHeader(
            title: 'Users',
            actionLabel: 'Add user',
            onAction: () => _showUserDialog(context),
          ),
          const SizedBox(height: 8),
          _UsersTable(
            users: state.adminUsers,
            currentUserId: state.currentUser?.userId,
            onEdit: (user) => _showUserDialog(context, user: user),
            onDelete: (user) => _confirmDeleteUser(context, user),
          ),

          const SizedBox(height: 24),

          _AdminSectionHeader(
            title: 'Cows',
            actionLabel: 'Add cow',
            onAction: () => _showCowDialog(context),
          ),
          const SizedBox(height: 8),
          _CowsTable(
            cows: state.adminCows,
            onEdit: (cow) => _showCowDialog(context, cow: cow),
            onDelete: (cow) => _confirmDeleteCow(context, cow),
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
              title: Text(isEdit ? 'Edit user' : 'Add user'),
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
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                          ),
                          validator: AppValidators.fullName,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                          ),
                          validator: AppValidators.email,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordCtrl,
                          obscureText: obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: isEdit
                                ? 'Password (leave empty to keep unchanged)'
                                : 'Password',
                            helperText: isEdit
                                ? 'Only enter a new password if you want to change it.'
                                : 'At least 8 characters with letters and numbers.',
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
                          validator: (value) {
                            if (!isEdit) {
                              return AppValidators.strongPassword(value);
                            }
                            if ((value ?? '').trim().isEmpty) {
                              return null;
                            }
                            return AppValidators.strongPassword(value);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: farmIdCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Farm ID',
                          ),
                          validator: (value) => AppValidators.requiredField(
                            value,
                            fieldName: 'Farm ID',
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: role,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'farmer',
                              child: Text('Farmer'),
                            ),
                            DropdownMenuItem(
                              value: 'veterinarian',
                              child: Text('Veterinarian'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setLocalState(() => role = value);
                            }
                          },
                          validator: (value) => AppValidators.requiredField(
                            value,
                            fieldName: 'Role',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final valid = formKey.currentState?.validate() ?? false;
                    if (!valid) return;
                    Navigator.pop(ctx, true);
                  },
                  child: Text(isEdit ? 'Save' : 'Create'),
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
        isEdit ? 'User updated successfully.' : 'User added successfully.',
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
          title: Text(isEdit ? 'Edit cow' : 'Add cow'),
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
                      decoration: const InputDecoration(
                        labelText: 'Cow ID',
                      ),
                      validator: (value) => AppValidators.requiredField(
                        value,
                        fieldName: 'Cow ID',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                      ),
                      validator: (value) => AppValidators.requiredField(
                        value,
                        fieldName: 'Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: tagNumberCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Tag number',
                      ),
                      validator: (value) => AppValidators.requiredField(
                        value,
                        fieldName: 'Tag number',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: breedCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Breed',
                      ),
                      validator: (value) => AppValidators.requiredField(
                        value,
                        fieldName: 'Breed',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: ageMonthsCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Age in months',
                      ),
                      validator: (value) => AppValidators.positiveInteger(
                        value,
                        fieldName: 'Age in months',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: deviceIdCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Device ID',
                      ),
                      validator: (value) => AppValidators.requiredField(
                        value,
                        fieldName: 'Device ID',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: farmIdCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Farm ID',
                      ),
                      validator: (value) => AppValidators.requiredField(
                        value,
                        fieldName: 'Farm ID',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final valid = formKey.currentState?.validate() ?? false;
                if (!valid) return;
                Navigator.pop(ctx, true);
              },
              child: Text(isEdit ? 'Save' : 'Create'),
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
        isEdit ? 'Cow updated successfully.' : 'Cow added successfully.',
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user'),
        content: Text('Are you sure you want to delete ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final success = await state.adminDeleteUser(user.userId);
    if (!mounted) return;

    if (success) {
      _showSuccess('User deleted successfully.');
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete cow'),
        content: Text('Are you sure you want to delete ${cow.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final success = await state.adminDeleteCow(cow.cowId);
    if (!mounted) return;

    if (success) {
      _showSuccess('Cow deleted successfully.');
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

  const _AdminAlertCard({
    required this.alert,
    required this.cows,
  });

  @override
  Widget build(BuildContext context) {
    final cow = cows.where((c) => c.id == alert.cowId).firstOrNull;

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
                    alert.title,
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
                    alert.details,
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

  const _UsersTable({
    required this.users,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No users found.'),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Full name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Farm')),
            DataColumn(label: Text('Created')),
            DataColumn(label: Text('Actions')),
          ],
          rows: users.map((user) {
            final isSelf = currentUserId == user.userId;
            return DataRow(
              cells: [
                DataCell(Text(user.fullName)),
                DataCell(Text(user.email)),
                DataCell(Text(user.role)),
                DataCell(Text(user.farmId)),
                DataCell(Text(user.createdAt.isEmpty ? '--' : user.createdAt)),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => onEdit(user),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: isSelf ? 'Cannot delete yourself' : 'Delete',
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

  const _CowsTable({
    required this.cows,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (cows.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No cows found.'),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Cow ID')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Tag')),
            DataColumn(label: Text('Breed')),
            DataColumn(label: Text('Age')),
            DataColumn(label: Text('Farm')),
            DataColumn(label: Text('Device')),
            DataColumn(label: Text('Actions')),
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
                        tooltip: 'Edit',
                        onPressed: () => onEdit(cow),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/api_models.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/liv_theme.dart';
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

  Future<void> _showUserDialog(
    BuildContext context, {
    ApiUser? user,
  }) async {
    final state = context.read<AppState>();
    final isEdit = user != null;

    final fullNameCtrl = TextEditingController(text: user?.fullName ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final passwordCtrl = TextEditingController();
    final farmIdCtrl = TextEditingController(text: user?.farmId ?? 'farm1');
    String role = user?.role ?? 'farmer';

    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
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
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                          ),
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'Required';
                            if (!value.contains('@')) return 'Invalid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordCtrl,
                          decoration: InputDecoration(
                            labelText: isEdit
                                ? 'Password (leave empty to keep unchanged)'
                                : 'Password',
                          ),
                          validator: (v) {
                            if (!isEdit && (v == null || v.isEmpty)) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: farmIdCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Farm ID',
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(isEdit ? 'Save' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;
    if (!formKey.currentState!.validate()) return;

    bool success;
    if (isEdit) {
      final updates = <String, dynamic>{
        'fullName': fullNameCtrl.text.trim(),
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
        fullName: fullNameCtrl.text.trim(),
        farmId: farmIdCtrl.text.trim(),
        role: role,
      );
    }

    if (!mounted) return;

    if (!success && state.adminErrorMessage != null) {
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

    final cowIdCtrl = TextEditingController(text: cow?.cowId ?? '');
    final nameCtrl = TextEditingController(text: cow?.name ?? '');
    final tagNumberCtrl = TextEditingController(text: cow?.tagNumber ?? '');
    final breedCtrl = TextEditingController(text: cow?.breed ?? '');
    final ageMonthsCtrl =
        TextEditingController(text: cow != null ? '${cow.ageMonths}' : '');
    final deviceIdCtrl = TextEditingController(text: cow?.deviceId ?? '');
    final farmIdCtrl = TextEditingController(text: cow?.farmId ?? 'farm1');

    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
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
                      decoration: const InputDecoration(labelText: 'Cow ID'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: tagNumberCtrl,
                      decoration: const InputDecoration(labelText: 'Tag number'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: breedCtrl,
                      decoration: const InputDecoration(labelText: 'Breed'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: ageMonthsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Age in months'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (int.tryParse(v.trim()) == null) return 'Must be a number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: deviceIdCtrl,
                      decoration: const InputDecoration(labelText: 'Device ID'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: farmIdCtrl,
                      decoration: const InputDecoration(labelText: 'Farm ID'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
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
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Save' : 'Create'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;
    if (!formKey.currentState!.validate()) return;

    bool success;
    if (isEdit) {
      success = await state.adminUpdateCow(
        cowId: cow.cowId,
        updates: {
          'name': nameCtrl.text.trim(),
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
        name: nameCtrl.text.trim(),
        tagNumber: tagNumberCtrl.text.trim(),
        breed: breedCtrl.text.trim(),
        ageMonths: int.parse(ageMonthsCtrl.text.trim()),
        deviceId: deviceIdCtrl.text.trim(),
      );
    }

    if (!mounted) return;

    if (!success && state.adminErrorMessage != null) {
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

    if (!success && state.adminErrorMessage != null) {
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

    if (!success && state.adminErrorMessage != null) {
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
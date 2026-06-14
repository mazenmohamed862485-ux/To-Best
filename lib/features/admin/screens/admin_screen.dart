// lib/features/admin/screens/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/tb_snackbar.dart';
import '../../../shared/widgets/tb_button.dart';
import '../../../features/auth/data/models/user_model.dart';

final adminUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final api = ref.read(apiClientProvider);
  final rows = await api.fetchAllUsers();
  if (rows == null) {
    // Fallback to local cache
    final db = ref.read(localDbProvider);
    final local = await db.getAllUsers();
    return local.map(UserModel.fromMap).toList();
  }
  return rows.map(UserModel.fromMap).toList();
});

final adminUsersRefreshProvider = StateProvider<int>((ref) => 0);

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});
  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _searchQ = '';
  String _filterRole = 'all';
  String _filterStatus = 'all';

  bool get _isSuperAdmin =>
      ref.read(authProvider).user?.isSuperAdmin ?? false;

  @override
  void initState() {
    super.initState();
    // Read superAdmin flag synchronously so TabController length matches
    // the actual number of tabs/children rendered in the build method.
    final tabCount = _isSuperAdmin ? 5 : 4;
    _tab = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final isSuperAdmin = authState.user?.isSuperAdmin ?? false;

    // Rebuild TabController if superAdmin status changed after initial creation
    if (_tab.length != (isSuperAdmin ? 5 : 4)) {
      _tab.dispose();
      _tab = TabController(length: isSuperAdmin ? 5 : 4, vsync: this);
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.admin_panel_settings, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 8),
          Text(l['admin']),
        ]),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: [
            Tab(text: l['users']),
            Tab(text: l['auditLog']),
            Tab(text: l['programRequests']),
            Tab(text: l['subscriptionRequests']),
            if (isSuperAdmin) Tab(text: l['banManagement']),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _UsersTab(
            searchQ: _searchQ,
            filterRole: _filterRole,
            filterStatus: _filterStatus,
            onSearch: (v) => setState(() => _searchQ = v),
            onFilterRole: (v) => setState(() => _filterRole = v),
            onFilterStatus: (v) => setState(() => _filterStatus = v),
            isDark: isDark,
            l: l,
          ),
          _AuditLogTab(l: l, isDark: isDark),
          _ProgramRequestsTab(l: l, isDark: isDark),
          _SubscriptionRequestsTab(l: l, isDark: isDark),
          if (isSuperAdmin) _BanManagementTab(l: l, isDark: isDark),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context, l),
        icon: const Icon(Icons.person_add_outlined),
        label: Text(l['addUser']),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, AppLocalizations l) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'trainee';
    String status = 'active';
    String program = 'UL';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(l['addUser']),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl,
                  decoration: InputDecoration(labelText: l['fullName'])),
              const SizedBox(height: 10),
              TextField(controller: emailCtrl,
                  decoration: InputDecoration(labelText: l['email'])),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl,
                  decoration: InputDecoration(labelText: l['phone'])),
              const SizedBox(height: 10),
              TextField(controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l['password'])),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: role,
                decoration: InputDecoration(labelText: l['role']),
                items: ['trainee', 'viewer', 'coach', 'admin']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setS(() => role = v!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: status,
                decoration: InputDecoration(labelText: l['status']),
                items: ['active', 'pending', 'inactive']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setS(() => status = v!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: program,
                decoration: InputDecoration(labelText: l['program']),
                items: ['UL', 'AP', 'FB', 'ARNOLD', 'PPL', 'CUSTOM']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setS(() => program = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text(l['cancel'])),
            TextButton(
              onPressed: () async {
                final api = ref.read(apiClientProvider);
                final ok = await api.adminAddUser({
                  'name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim().toLowerCase(),
                  'phone': phoneCtrl.text.trim(),
                  'password': passCtrl.text,
                  'role': role,
                  'status': status,
                  'program': program,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  TbSnackbar.show(context, ok ? l['saved'] : l['error'],
                      isSuccess: ok, isError: !ok);
                }
                ref.invalidate(adminUsersProvider);
              },
              child: Text(l['add']),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Users Tab ─────────────────────────────────────────────────
class _UsersTab extends ConsumerWidget {
  final String searchQ, filterRole, filterStatus;
  final void Function(String) onSearch, onFilterRole, onFilterStatus;
  final bool isDark;
  final AppLocalizations l;

  const _UsersTab({
    required this.searchQ,
    required this.filterRole,
    required this.filterStatus,
    required this.onSearch,
    required this.onFilterRole,
    required this.onFilterStatus,
    required this.isDark,
    required this.l,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Column(
      children: [
        // Search + filters
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                onChanged: onSearch,
                decoration: InputDecoration(
                  hintText: '${l['users']}…',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: filterRole,
                      isDense: true,
                      decoration: InputDecoration(
                        labelText: l['role'],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                      items: ['all', 'trainee', 'viewer', 'coach', 'admin', 'superadmin']
                          .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (v) => onFilterRole(v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: filterStatus,
                      isDense: true,
                      decoration: InputDecoration(
                        labelText: l['status'],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                      items: ['all', 'active', 'pending', 'rejected', 'inactive']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (v) => onFilterStatus(v!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: usersAsync.when(
            data: (users) {
              final filtered = users.where((u) {
                final q = searchQ.toLowerCase();
                final matchQ = q.isEmpty ||
                    u.name.toLowerCase().contains(q) ||
                    u.email.toLowerCase().contains(q) ||
                    u.phone.toLowerCase().contains(q);
                final matchRole =
                    filterRole == 'all' || u.role == filterRole;
                final matchStatus =
                    filterStatus == 'all' || u.status == filterStatus;
                return matchQ && matchRole && matchStatus;
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) => _UserCard(
                  user: filtered[i],
                  isDark: isDark,
                  l: l,
                ),
              );
            },
            loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryGreen)),
            error: (e, _) => Center(child: Text('$e')),
          ),
        ),
      ],
    );
  }
}

class _UserCard extends ConsumerWidget {
  final UserModel user;
  final bool isDark;
  final AppLocalizations l;
  const _UserCard({required this.user, required this.isDark, required this.l});

  Color _statusColor() {
    switch (user.status) {
      case 'active': return AppColors.success;
      case 'pending': return AppColors.warning;
      case 'rejected': return AppColors.error;
      default: return AppColors.darkTextMuted;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
              backgroundImage: user.pictureUrl != null
                  ? NetworkImage(user.pictureUrl!)
                  : null,
              child: user.pictureUrl == null
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w700))
                  : null,
            ),
            title: Text(user.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text('${user.email}\n${user.role} • ${user.program}',
                style: const TextStyle(fontSize: 11)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor().withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(user.status,
                  style: TextStyle(
                      color: _statusColor(), fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ),
          // Action buttons for pending users
          if (user.status == 'pending')
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approve(context, ref),
                      icon: const Icon(Icons.check, size: 14),
                      label: Text(l['approveUser'],
                          style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reject(context, ref),
                      icon: const Icon(Icons.close, size: 14, color: AppColors.error),
                      label: Text(l['rejectUser'],
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 8)),
                    ),
                  ),
                ],
              ),
            ),
          // Admin action row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: Text(l['edit'], style: const TextStyle(fontSize: 12)),
                  onPressed: () => _showEditDialog(context, ref),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 14,
                      color: AppColors.error),
                  label: Text(l['delete'],
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.error)),
                  onPressed: () => _delete(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final api = ref.read(apiClientProvider);
    final ok = await api.adminApproveUser(user.uid, true);
    if (context.mounted) {
      TbSnackbar.show(context, ok ? l['saved'] : l['error'],
          isSuccess: ok, isError: !ok);
    }
    ref.invalidate(adminUsersProvider);
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final api = ref.read(apiClientProvider);
    final ok = await api.adminApproveUser(user.uid, false);
    if (context.mounted) {
      TbSnackbar.show(context, ok ? l['saved'] : l['error'],
          isSuccess: ok, isError: !ok);
    }
    ref.invalidate(adminUsersProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l['deleteUser']),
        content: Text('${l['delete']} ${user.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l['cancel'])),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l['delete']),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final api = ref.read(apiClientProvider);
    final ok = await api.adminDeleteUser(user.uid);
    if (context.mounted) {
      TbSnackbar.show(context, ok ? l['saved'] : l['error'],
          isSuccess: ok, isError: !ok);
    }
    ref.invalidate(adminUsersProvider);
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    final calCtrl = TextEditingController(text: user.dailyCalories.toStringAsFixed(0));
    String role = user.role;
    String status = user.status;
    String program = user.program;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(l['editUser']),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl,
                  decoration: InputDecoration(labelText: l['fullName'])),
              const SizedBox(height: 8),
              TextField(controller: phoneCtrl,
                  decoration: InputDecoration(labelText: l['phone'])),
              const SizedBox(height: 8),
              TextField(controller: calCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l['dailyCals'])),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: role,
                decoration: InputDecoration(labelText: l['role']),
                items: ['trainee', 'viewer', 'coach', 'admin', 'superadmin']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setS(() => role = v!),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: status,
                decoration: InputDecoration(labelText: l['status']),
                items: ['active', 'pending', 'rejected', 'inactive']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setS(() => status = v!),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: program,
                decoration: InputDecoration(labelText: l['program']),
                items: ['UL', 'AP', 'FB', 'ARNOLD', 'PPL', 'CUSTOM']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setS(() => program = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text(l['cancel'])),
            TextButton(
              onPressed: () async {
                final api = ref.read(apiClientProvider);
                final ok = await api.adminUpdateUser(user.uid, {
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'role': role,
                  'status': status,
                  'program': program,
                  'dailyCalories': double.tryParse(calCtrl.text) ?? user.dailyCalories,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  TbSnackbar.show(context, ok ? l['saved'] : l['error'],
                      isSuccess: ok, isError: !ok);
                }
                ref.invalidate(adminUsersProvider);
              },
              child: Text(l['save']),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Audit Log Tab ─────────────────────────────────────────────
class _AuditLogTab extends ConsumerWidget {
  final AppLocalizations l;
  final bool isDark;
  const _AuditLogTab({required this.l, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(apiClientProvider).getAuditLog(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen));
        }
        final logs = snap.data ?? [];
        if (logs.isEmpty) {
          return Center(child: Text(l['noData']));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: logs.length,
          itemBuilder: (ctx, i) {
            final log = logs[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(log['action']?.toString() ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                Text('${log['adminId']} → ${log['targetId']}',
                    style: const TextStyle(fontSize: 11)),
                Text(log['timestamp']?.toString() ?? '',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.darkTextMuted)),
              ]),
            );
          },
        );
      },
    );
  }
}

// ── Program Requests Tab ──────────────────────────────────────
class _ProgramRequestsTab extends StatelessWidget {
  final AppLocalizations l;
  final bool isDark;
  const _ProgramRequestsTab({required this.l, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.change_circle_outlined,
                size: 56, color: AppColors.primaryGreen),
            const SizedBox(height: 16),
            Text(l['programRequests'],
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l['noData'],
                style: const TextStyle(color: AppColors.darkTextSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Subscription Requests Tab ─────────────────────────────────
class _SubscriptionRequestsTab extends ConsumerWidget {
  final AppLocalizations l;
  final bool isDark;
  const _SubscriptionRequestsTab({required this.l, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(apiClientProvider).getSubscriptionRequests(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen));
        }
        final requests = snap.data ?? [];
        if (requests.isEmpty) {
          return Center(child: Text(l['noData']));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requests.length,
          itemBuilder: (ctx, i) {
            final req = requests[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(req['userName']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(req['plan']?.toString() ?? '',
                    style: const TextStyle(color: AppColors.primaryGreen)),
                Text(req['timestamp']?.toString() ?? '',
                    style: const TextStyle(fontSize: 11)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final api = ref.read(apiClientProvider);
                        await api.updateSubscriptionRequest(
                            req['id']?.toString() ?? '', 'approved', {});
                        if (context.mounted) {
                          TbSnackbar.show(context, l['saved'], isSuccess: true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success),
                      child: Text(l['approvePayment'],
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final api = ref.read(apiClientProvider);
                        await api.updateSubscriptionRequest(
                            req['id']?.toString() ?? '', 'rejected', {});
                        if (context.mounted) {
                          TbSnackbar.show(context, l['saved'], isSuccess: true);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          foregroundColor: AppColors.error),
                      child: Text(l['rejectPayment'],
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ]),
              ]),
            );
          },
        );
      },
    );
  }
}

// ── Ban Management Tab ────────────────────────────────────────
class _BanManagementTab extends ConsumerWidget {
  final AppLocalizations l;
  final bool isDark;
  const _BanManagementTab({required this.l, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(apiClientProvider).listBanned(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen));
        }
        final list = (snap.data?['list'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        if (list.isEmpty) {
          return Center(child: Text(l['noData']));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final ban = list[i];
            return ListTile(
              leading: const Icon(Icons.block, color: AppColors.error),
              title: Text(ban['email']?.toString() ?? ''),
              subtitle: Text(ban['reason']?.toString() ?? ''),
              trailing: TextButton(
                onPressed: () async {
                  await ref.read(apiClientProvider).unbanIdentity(
                      ban['id']?.toString() ?? '');
                  if (context.mounted) {
                    TbSnackbar.show(context, l['saved'], isSuccess: true);
                  }
                },
                child: Text(l['unban'],
                    style: const TextStyle(color: AppColors.primaryGreen)),
              ),
            );
          },
        );
      },
    );
  }
}

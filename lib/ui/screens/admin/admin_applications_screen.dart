import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/application_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';

/// Admin screen to view & manage applications (all or per-hackathon)
class AdminApplicationsScreen extends StatefulWidget {
  final String? hackathonId;
  final String? hackathonTitle;

  const AdminApplicationsScreen({
    super.key,
    this.hackathonId,
    this.hackathonTitle,
  });

  @override
  State<AdminApplicationsScreen> createState() =>
      _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ApplicationModel> _hackathonApps = [];
  bool _loadingHackathonApps = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.hackathonId != null) {
        _loadHackathonApplications();
      } else {
        context.read<AdminProvider>().loadApplications();
      }
    });
  }

  Future<void> _loadHackathonApplications() async {
    setState(() => _loadingHackathonApps = true);
    _hackathonApps = await context
        .read<AdminProvider>()
        .loadApplicationsForHackathon(widget.hackathonId!);
    setState(() => _loadingHackathonApps = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ApplicationModel> get _allApps =>
      widget.hackathonId != null
          ? _hackathonApps
          : context.read<AdminProvider>().applications;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hackathonTitle != null
            ? 'Applications: ${widget.hackathonTitle}'
            : 'All Applications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          final isLoading = widget.hackathonId != null
              ? _loadingHackathonApps
              : provider.isLoading;

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final apps = _allApps;
          final pending = apps
              .where((a) => a.status == ApplicationStatus.pending)
              .toList();
          final approved = apps
              .where((a) => a.status == ApplicationStatus.approved)
              .toList();
          final rejected = apps
              .where((a) => a.status == ApplicationStatus.rejected)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _ApplicationListView(
                applications: pending,
                emptyLabel: 'No pending applications',
                showActions: true,
              ),
              _ApplicationListView(
                applications: approved,
                emptyLabel: 'No approved applications',
                showActions: false,
              ),
              _ApplicationListView(
                applications: rejected,
                emptyLabel: 'No rejected applications',
                showActions: false,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ApplicationListView extends StatelessWidget {
  final List<ApplicationModel> applications;
  final String emptyLabel;
  final bool showActions;

  const _ApplicationListView({
    required this.applications,
    required this.emptyLabel,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(emptyLabel,
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final app = applications[index];
        return _ApplicationCard(
          application: app,
          showActions: showActions,
        ).animate().fadeIn(
              duration: 350.ms,
              delay: Duration(milliseconds: 40 * index),
            );
      },
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  final bool showActions;

  const _ApplicationCard({
    required this.application,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = switch (application.status) {
      ApplicationStatus.pending => AppColors.accentOrange,
      ApplicationStatus.approved => AppColors.secondaryGreen,
      ApplicationStatus.rejected => AppColors.error,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                  child: Text(
                    application.userName.isNotEmpty
                        ? application.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(application.userName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (application.isTeamApplication)
                        Text(
                          'Team: ${application.teamName ?? 'N/A'}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    application.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Applied: ${_formatDate(application.appliedAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            if (application.remarks != null &&
                application.remarks!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Remarks: ${application.remarks}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
            if (showActions) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _reject(context),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _approve(context),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _approve(BuildContext context) async {
    final adminUid = context.read<AuthProvider>().currentUserId ?? '';
    final success = await context
        .read<AdminProvider>()
        .approveApplication(application.id, adminUid);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application approved')),
      );
    }
  }

  void _reject(BuildContext context) async {
    final remarksCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Application'),
        content: TextField(
          controller: remarksCtrl,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            hintText: 'Enter rejection reason...',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final adminUid = context.read<AuthProvider>().currentUserId ?? '';
      final success = await context.read<AdminProvider>().rejectApplication(
            application.id,
            adminUid,
            remarks: remarksCtrl.text.trim().isNotEmpty
                ? remarksCtrl.text.trim()
                : null,
          );
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application rejected')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

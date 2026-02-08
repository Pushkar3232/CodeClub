import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/hackathon_model.dart';
import '../../../providers/admin_provider.dart';

/// Admin hackathon management screen
class AdminHackathonListScreen extends StatefulWidget {
  const AdminHackathonListScreen({super.key});

  @override
  State<AdminHackathonListScreen> createState() =>
      _AdminHackathonListScreenState();
}

class _AdminHackathonListScreenState extends State<AdminHackathonListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadHackathons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Hackathons'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/admin/hackathons/add'),
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hackathons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No hackathons yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.push('/admin/hackathons/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Hackathon'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadHackathons(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.hackathons.length,
              itemBuilder: (context, index) {
                final hackathon = provider.hackathons[index];
                return _AdminHackathonCard(
                  hackathon: hackathon,
                  onEdit: () => context.push(
                    '/admin/hackathons/edit',
                    extra: hackathon,
                  ),
                  onDelete: () => _confirmDelete(context, provider, hackathon),
                  onViewApps: () => context.push(
                    '/admin/hackathon-applications/${hackathon.id}',
                    extra: hackathon.title,
                  ),
                ).animate().fadeIn(
                      duration: 400.ms,
                      delay: Duration(milliseconds: 50 * index),
                    );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AdminProvider provider,
      HackathonModel hackathon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Hackathon'),
        content: Text(
            'Are you sure you want to delete "${hackathon.title}"? This will also delete all related applications.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await provider.deleteHackathon(hackathon.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hackathon deleted')),
        );
      }
    }
  }
}

/// Admin hackathon card widget
class _AdminHackathonCard extends StatelessWidget {
  final HackathonModel hackathon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewApps;

  const _AdminHackathonCard({
    required this.hackathon,
    required this.onEdit,
    required this.onDelete,
    required this.onViewApps,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = hackathon.isUpcoming
        ? AppColors.primaryBlue
        : hackathon.isOngoing
            ? AppColors.secondaryGreen
            : Colors.grey;
    final statusLabel = hackathon.isUpcoming
        ? 'Upcoming'
        : hackathon.isOngoing
            ? 'Ongoing'
            : 'Ended';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    hackathon.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hackathon.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(hackathon.startDate)} — ${_formatDate(hackathon.endDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const Spacer(),
                Icon(Icons.people_outline_rounded,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${hackathon.totalRegistrations} registrations',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _ActionChip(
                  icon: Icons.visibility_outlined,
                  label: 'Applications',
                  onTap: onViewApps,
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: onEdit,
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  onTap: onDelete,
                  color: AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primaryBlue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: c.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: c, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

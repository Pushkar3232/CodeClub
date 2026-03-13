import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../providers/admin_provider.dart';
import '../widgets/admin_auth_guard.dart';
import '../widgets/stat_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AdminProvider>();
      await provider.loadDashboardStats();
      await provider.loadAllHackathons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminAuthGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CodeClub Admin'),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await context.read<AdminProvider>().signOutAdmin();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ],
        ),
        body: Consumer<AdminProvider>(
          builder: (context, provider, _) {
            final stats = provider.dashStats;
            final adminName = provider.currentAdmin?.displayName ?? 'Admin';

            return RefreshIndicator(
              onRefresh: () async {
                await provider.loadDashboardStats();
                await provider.loadAllHackathons();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.primaryBlue,
                            child: Icon(Icons.shield_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back, $adminName',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(DateTime.now().formattedDateTime),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.35,
                    children: [
                      StreamBuilder<int>(
                        stream: provider.totalUsersStream,
                        builder: (context, snapshot) => StatCard(
                          label: 'Total Users',
                          icon: Icons.people_alt_rounded,
                          color: AppColors.primaryBlue,
                          value: '${snapshot.data ?? stats?.totalUsers ?? 0}',
                        ),
                      ),
                      StreamBuilder<int>(
                        stream: provider.totalTeamsStream,
                        builder: (context, snapshot) => StatCard(
                          label: 'Total Teams',
                          icon: Icons.groups_rounded,
                          color: AppColors.secondaryGreen,
                          value: '${snapshot.data ?? stats?.totalTeams ?? 0}',
                        ),
                      ),
                      StreamBuilder<int>(
                        stream: provider.activeHackathonsStream,
                        builder: (context, snapshot) => StatCard(
                          label: 'Active Hackathons',
                          icon: Icons.emoji_events_rounded,
                          color: AppColors.warning,
                          value: '${snapshot.data ?? stats?.activeHackathons ?? 0}',
                        ),
                      ),
                      StatCard(
                        label: 'Registrations',
                        icon: Icons.how_to_reg_rounded,
                        color: AppColors.info,
                        value:
                            '${(stats?.totalRegisteredTeams ?? 0) + (stats?.totalRegisteredIndividuals ?? 0)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.push('/admin/hackathons/create'),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create Hackathon'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.push('/admin/hackathons'),
                          child: const Text('View All'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Recent Hackathons',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...provider.hackathons.take(5).map((hackathon) {
                    return Card(
                      child: ListTile(
                        title: Text(hackathon.title),
                        subtitle: Text(hackathon.startDate.formattedDate),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push(
                          '/admin/hackathons/detail',
                          extra: hackathon,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/admin/hackathons/create'),
          icon: const Icon(Icons.add),
          label: const Text('New Hackathon'),
        ),
      ),
    );
  }
}

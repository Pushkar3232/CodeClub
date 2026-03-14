import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/models/hackathon_model.dart';
import '../../../providers/admin_provider.dart';
import '../widgets/admin_auth_guard.dart';
import '../widgets/hackathon_admin_tile.dart';

class AdminHackathonListScreen extends StatefulWidget {
  const AdminHackathonListScreen({super.key});

  @override
  State<AdminHackathonListScreen> createState() => _AdminHackathonListScreenState();
}

class _AdminHackathonListScreenState extends State<AdminHackathonListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAllHackathons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminAuthGuard(
      child: Scaffold(
        appBar: AppBar(title: const Text('Manage Hackathons')),
        body: Consumer<AdminProvider>(
          builder: (context, provider, _) {
            final list = provider.filteredHackathons;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by title or venue',
                      prefixIcon: Icon(Icons.search_rounded),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: provider.setSearchQuery,
                  ),
                ),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: provider.filterStatus == null,
                        onTap: () => provider.setFilter(null),
                      ),
                      ...HackathonStatus.values.map(
                        (status) => _FilterChip(
                          label: status.label,
                          selected: provider.filterStatus == status,
                          onTap: () => provider.setFilter(status),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => provider.loadAllHackathons(),
                          child: list.isEmpty
                              ? ListView(
                                  children: [
                                    SizedBox(height: 120),
                                    Center(child: Text('No hackathons found.')),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: list.length,
                                  itemBuilder: (context, index) {
                                    final hackathon = list[index];
                                    return Dismissible(
                                      key: ValueKey(hackathon.id),
                                      background: Container(
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.only(left: 16),
                                        color: Colors.red.withValues(alpha: 0.2),
                                        child: const Icon(Icons.delete_outline_rounded),
                                      ),
                                      direction: DismissDirection.startToEnd,
                                      confirmDismiss: (_) => _confirmDelete(
                                        context,
                                        hackathon,
                                      ),
                                      onDismissed: (_) async {
                                        await provider.deleteHackathon(hackathon.id);
                                      },
                                      child: HackathonAdminTile(
                                        hackathon: hackathon,
                                        onTap: () => context.push(
                                          '/admin/hackathons/detail',
                                          extra: hackathon,
                                        ),
                                        onEdit: () => context.push(
                                          '/admin/hackathons/edit',
                                          extra: hackathon,
                                        ),
                                        onDelete: () async {
                                          final confirmed = await _confirmDelete(
                                            context,
                                            hackathon,
                                          );
                                          if (confirmed == true && context.mounted) {
                                            await context
                                                .read<AdminProvider>()
                                                .deleteHackathon(hackathon.id);
                                          }
                                        },
                                        onStatusChange: (status) async {
                                          await context
                                              .read<AdminProvider>()
                                              .toggleStatus(hackathon.id, status);
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/admin/hackathons/create'),
          icon: const Icon(Icons.add),
          label: const Text('Create'),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, HackathonModel hackathon) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hackathon?'),
        content: Text(
          "This will hide '${hackathon.title}' from students. Registered teams will not be affected.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

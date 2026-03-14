import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/extensions.dart';
import '../../../data/models/hackathon_model.dart';
import '../../../providers/admin_provider.dart';
import '../widgets/admin_auth_guard.dart';
import '../widgets/status_badge.dart';

class AdminHackathonDetailScreen extends StatelessWidget {
  final HackathonModel hackathon;

  const AdminHackathonDetailScreen({super.key, required this.hackathon});

  @override
  Widget build(BuildContext context) {
    return AdminAuthGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hackathon Details'),
          actions: [
            IconButton(
              onPressed: () => context.push('/admin/hackathons/edit', extra: hackathon),
              icon: const Icon(Icons.edit_rounded),
            ),
            IconButton(
              onPressed: () async {
                final ok = await _confirmDelete(context);
                if (ok == true && context.mounted) {
                  await context.read<AdminProvider>().deleteHackathon(hackathon.id);
                  if (context.mounted) {
                    context.pop();
                  }
                }
              },
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (hackathon.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  hackathon.imageUrl!,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              hackathon.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            StatusBadge(status: hackathon.status),
            const SizedBox(height: 16),
            _Info(label: 'Description', value: hackathon.description),
            _Info(label: 'Venue', value: hackathon.venue),
            _Info(
              label: 'Timeline',
              value:
                  '${hackathon.startDate.formattedDateTime} -> ${hackathon.endDate.formattedDateTime}',
            ),
            _Info(
              label: 'Registration Deadline',
              value: hackathon.registrationDeadline.formattedDateTime,
            ),
            _Info(
              label: 'Team Size',
              value: '${hackathon.minTeamSize}-${hackathon.maxTeamSize}',
            ),
            _Info(
              label: 'Registration Form',
              value: hackathon.registrationFormUrl.isNotEmpty
                  ? hackathon.registrationFormUrl
                  : 'No form URL provided',
            ),
            if (hackathon.prizes.isNotEmpty)
              _Info(label: 'Prizes', value: hackathon.prizes.join('\n')),
            if ((hackathon.rules ?? const <String>[]).isNotEmpty)
              _Info(label: 'Rules', value: hackathon.rules!.join('\n')),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hackathon?'),
        content: Text(
          "This will hide '${hackathon.title}' from all students. This action can be reviewed by a superadmin.",
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

class _Info extends StatelessWidget {
  final String label;
  final String value;

  const _Info({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}

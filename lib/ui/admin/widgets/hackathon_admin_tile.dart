import 'package:flutter/material.dart';

import '../../../core/utils/extensions.dart';
import '../../../data/models/hackathon_model.dart';
import 'status_badge.dart';

class HackathonAdminTile extends StatelessWidget {
  final HackathonModel hackathon;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<HackathonStatus> onStatusChange;

  const HackathonAdminTile({
    super.key,
    required this.hackathon,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 56,
            height: 56,
            child: hackathon.imageUrl != null
                ? Image.network(hackathon.imageUrl!, fit: BoxFit.cover)
                : Container(
                    color: Colors.black12,
                    child: const Icon(Icons.emoji_events_rounded),
                  ),
          ),
        ),
        title: Text(
          hackathon.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${hackathon.startDate.formattedDate} | ${hackathon.registeredTeamIds.length} teams',
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            } else {
              onStatusChange(hackathonStatusFromString(value));
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'published', child: Text('Mark Published')),
            const PopupMenuItem(value: 'ongoing', child: Text('Mark Ongoing')),
            const PopupMenuItem(value: 'completed', child: Text('Mark Completed')),
            const PopupMenuItem(value: 'cancelled', child: Text('Mark Cancelled')),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'delete', child: Text('Soft Delete')),
          ],
          child: StatusBadge(status: hackathon.status),
        ),
      ),
    );
  }
}

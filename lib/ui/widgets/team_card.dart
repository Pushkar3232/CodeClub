import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';

import '../../data/models/team_model.dart';
import '../../data/models/user_model.dart';
import 'user_card.dart';

/// Team card widget
class TeamCard extends StatelessWidget {
  final TeamModel team;
  final List<UserModel> members;
  final VoidCallback? onTap;
  final VoidCallback? onChatTap;

  const TeamCard({
    super.key,
    required this.team,
    required this.members,
    this.onTap,
    this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leader = members.where((m) => m.uid == team.leaderId).firstOrNull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team name and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: AppColors.primaryBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (team.hackathonName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            team.hackathonName!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primaryBlue,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Team status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: team.isOpen
                          ? AppColors.secondaryGreen.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      team.isOpen ? 'Open' : 'Closed',
                      style: TextStyle(
                        color: team.isOpen
                            ? AppColors.secondaryGreen
                            : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Team size indicator
              Row(
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 18,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${team.memberIds.length}/${team.maxSize} members',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  // Slots indicator
                  if (team.availableSlots > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlueLight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${team.availableSlots} slots available',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Member avatars
              SizedBox(
                height: 40,
                child: Row(
                  children: [
                    // Stacked avatars
                    ...members.take(4).toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final member = entry.value;
                      return Transform.translate(
                        offset: Offset(-index * 12.0, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: UserAvatar(
                            user: member,
                            radius: 18,
                          ),
                        ),
                      );
                    }),
                    if (members.length > 4)
                      Transform.translate(
                        offset: Offset(-4 * 12.0, 0),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '+${members.length - 4}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (onChatTap != null)
                      IconButton(
                        onPressed: onChatTap,
                        icon: const Icon(Icons.chat_bubble_rounded),
                        color: AppColors.primaryBlue,
                      ),
                  ],
                ),
              ),
              // Leader info
              if (leader != null) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.accentOrange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Led by ${leader.fullName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(
          begin: 0.05,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }
}

/// Mini team card for list views
class MiniTeamCard extends StatelessWidget {
  final TeamModel team;
  final VoidCallback? onTap;

  const MiniTeamCard({
    super.key,
    required this.team,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.groups_rounded,
            color: AppColors.primaryBlue,
          ),
        ),
        title: Text(
          team.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${team.memberIds.length}/${team.maxSize} members',
        ),
        trailing: Icon(
          team.isOpen ? Icons.lock_open_rounded : Icons.lock_rounded,
          color: team.isOpen ? AppColors.secondaryGreen : Colors.grey,
          size: 20,
        ),
      ),
    );
  }
}

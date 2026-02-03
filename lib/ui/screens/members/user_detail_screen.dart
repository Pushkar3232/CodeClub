import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/team_provider.dart';

import '../chat/chat_screen.dart';

/// User detail/profile view screen
class UserDetailScreen extends StatelessWidget {
  final UserModel user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with profile header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage: user.profileImageUrl != null
                            ? NetworkImage(user.profileImageUrl!)
                            : null,
                        child: user.profileImageUrl == null
                            ? Text(
                                user.fullName.initials,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ).animate().fadeIn(duration: 500.ms).scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1, 1),
                            duration: 500.ms,
                            curve: Curves.elasticOut,
                          ),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                      const SizedBox(height: 8),
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.role,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Profile content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.message_rounded,
                          label: 'Message',
                          onTap: () => _openChat(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.person_add_rounded,
                          label: 'Team Request',
                          isPrimary: true,
                          onTap: () => _sendTeamRequest(context),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                  const SizedBox(height: 24),
                  // Info cards
                  _InfoCard(
                    title: 'Academic Info',
                    icon: Icons.school_rounded,
                    children: [
                      _InfoRow(label: 'Branch', value: user.branch),
                      _InfoRow(label: 'Year', value: user.year),
                    ],
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(
                        begin: 0.05,
                        end: 0,
                        duration: 400.ms,
                      ),
                  const SizedBox(height: 16),
                  if (user.bio.isNotEmpty)
                    _InfoCard(
                      title: 'About',
                      icon: Icons.info_outline_rounded,
                      children: [
                        Text(
                          user.bio,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(
                          begin: 0.05,
                          end: 0,
                          duration: 400.ms,
                        ),
                  if (user.bio.isNotEmpty) const SizedBox(height: 16),
                  _InfoCard(
                    title: 'Skills',
                    icon: Icons.code_rounded,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.skills.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.primaryBlue.withValues(alpha: 0.2)
                                  : AppColors.primaryBlueLight.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              skill,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.primaryBlueLight
                                    : AppColors.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(
                        begin: 0.05,
                        end: 0,
                        duration: 400.ms,
                      ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChat(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final currentUserId = authProvider.currentUserId;
    
    if (currentUserId == null) return;

    final chat = await chatProvider.openChatWithUser(currentUserId, user.uid);
    
    if (chat != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chat.id,
            title: user.fullName,
          ),
        ),
      );
    }
  }

  Future<void> _sendTeamRequest(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final teamProvider = context.read<TeamProvider>();
    final currentUserId = authProvider.currentUserId;
    
    if (currentUserId == null) return;

    final success = await teamProvider.sendTeamRequest(
      fromUserId: currentUserId,
      toUserId: user.uid,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? AppConstants.requestSent
                : (teamProvider.errorMessage ?? 'Failed to send request'),
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Action button widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

/// Info card widget
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Info row widget
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

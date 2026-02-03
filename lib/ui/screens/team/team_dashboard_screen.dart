import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/team_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/user_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/team_provider.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/user_card.dart';
import '../chat/chat_screen.dart';

/// Team dashboard screen
class TeamDashboardScreen extends StatefulWidget {
  const TeamDashboardScreen({super.key});

  @override
  State<TeamDashboardScreen> createState() => _TeamDashboardScreenState();
}

class _TeamDashboardScreenState extends State<TeamDashboardScreen> {
  final UserService _userService = UserService();
  List<UserModel> _members = [];
  UserModel? _leader;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  Future<void> _loadTeamData() async {
    final teamProvider = context.read<TeamProvider>();
    final team = teamProvider.currentTeam;
    
    if (team == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Load leader
      // Leader ID is always available
      {
        _leader = await _userService.getUserById(team.leaderId);
      }
      
      // Load members
      _members = await _userService.getUsersByIds(
        team.memberIds.where((id) => id != team.leaderId).toList(),
      );
    } catch (e) {
      // Handle error
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openTeamChat() async {
    final teamProvider = context.read<TeamProvider>();
    final chatProvider = context.read<ChatProvider>();
    final team = teamProvider.currentTeam;
    
    if (team == null) return;

    final chat = await chatProvider.getOrCreateTeamChat(team.id, team.name);
    
    if (chat != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chat.id,
            title: team.name,
            isGroupChat: true,
          ),
        ),
      );
    }
  }

  Future<void> _leaveTeam() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Team'),
        content: const Text(
          'Are you sure you want to leave this team? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authProvider = context.read<AuthProvider>();
    final teamProvider = context.read<TeamProvider>();
    final userId = authProvider.currentUserId;
    
    if (userId == null) return;

    final success = await teamProvider.leaveTeam(userId);
    
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have left the team'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              teamProvider.errorMessage ?? 'Failed to leave team',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Team'),
        actions: [
          IconButton(
            onPressed: _openTeamChat,
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'leave') {
                _leaveTeam();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app_rounded, color: AppColors.error),
                    SizedBox(width: 12),
                    Text('Leave Team'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<TeamProvider>(
        builder: (context, teamProvider, _) {
          final team = teamProvider.currentTeam;

          if (team == null) {
            return _buildNoTeamState();
          }

          if (_isLoading) {
            return const Center(
              child: LoadingOverlay(
                isLoading: true,
                child: SizedBox.shrink(),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadTeamData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team header card
                  _TeamHeaderCard(team: team)
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: -0.05, end: 0, duration: 500.ms),
                  const SizedBox(height: 24),
                  // Team stats
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.people_rounded,
                          label: 'Members',
                          value: '${team.memberIds.length}/${team.maxSize}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.event_available_rounded,
                          label: 'Slots',
                          value: '${team.availableSlots} left',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: team.isOpen
                              ? Icons.lock_open_rounded
                              : Icons.lock_rounded,
                          label: 'Status',
                          value: team.isOpen ? 'Open' : 'Closed',
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  const SizedBox(height: 24),
                  // Leader section
                  Text(
                    'Team Leader',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                  const SizedBox(height: 12),
                  if (_leader != null)
                    _MemberCard(user: _leader!, isLeader: true)
                        .animate()
                        .fadeIn(delay: 350.ms, duration: 400.ms),
                  const SizedBox(height: 24),
                  // Members section
                  Text(
                    'Team Members',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                  const SizedBox(height: 12),
                  if (_members.isEmpty)
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_add_rounded,
                                size: 48,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No other members yet',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Invite people to join your team!',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 450.ms, duration: 400.ms)
                  else
                    Column(
                      children: _members
                          .asMap()
                          .entries
                          .map(
                            (entry) => _MemberCard(user: entry.value)
                                .animate(
                                  delay: Duration(
                                    milliseconds: 450 + (entry.key * 50),
                                  ),
                                )
                                .fadeIn(duration: 400.ms),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoTeamState() {
    return const EmptyStateWidget(
      icon: Icons.group_off_rounded,
      title: 'No team yet',
      subtitle: 'Create a team or join an existing one to get started',
    );
  }
}

/// Team header card
class _TeamHeaderCard extends StatelessWidget {
  final TeamModel team;

  const _TeamHeaderCard({required this.team});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      team.name.initials,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  team.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 18,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      team.hackathonName ?? 'No hackathon',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (team.description != null && team.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                team.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}

/// Stat card widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primaryBlue,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Member card widget
class _MemberCard extends StatelessWidget {
  final UserModel user;
  final bool isLeader;

  const _MemberCard({
    required this.user,
    this.isLeader = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: UserAvatar(user: user, radius: 24),
        title: Row(
          children: [
            Text(
              user.fullName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (isLeader) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Leader',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${user.role} • ${user.branch}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

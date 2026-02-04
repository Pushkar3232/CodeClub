import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/team_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/team_service.dart';
import '../../../data/services/user_service.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/team_card.dart';

/// Browse and join teams screen
class JoinTeamScreen extends StatefulWidget {
  const JoinTeamScreen({super.key});

  @override
  State<JoinTeamScreen> createState() => _JoinTeamScreenState();
}

class _JoinTeamScreenState extends State<JoinTeamScreen> {
  final TeamService _teamService = TeamService();
  final UserService _userService = UserService();
  
  List<TeamModel> _teams = [];
  Map<String, UserModel> _leaderCache = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTeams();
    });
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _teams = await _teamService.getOpenTeams();
      
      // Load leaders for all teams
      final leaderIds = _teams.map((t) => t.leaderId).toSet().toList();
      final leaders = await _userService.getUsersByIds(leaderIds);
      
      for (final leader in leaders) {
        _leaderCache[leader.uid] = leader;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showTeamDetails(TeamModel team) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _TeamDetailsSheet(
        team: team,
        leader: _leaderCache[team.leaderId],
        onRequestToJoin: () {
          // TODO: Implement request to join
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request sent to join team!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Teams'),
      ),
      body: _isLoading
          ? const ShimmerList(itemCount: 5, itemHeight: 160)
          : _errorMessage != null
              ? ErrorStateWidget(
                  message: _errorMessage!,
                  onRetry: _loadTeams,
                )
              : _teams.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.group_rounded,
                      title: 'No open teams',
                      subtitle:
                          'There are no teams looking for members right now',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTeams,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _teams.length,
                        itemBuilder: (context, index) {
                          final team = _teams[index];
                          
                          return TeamCard(
                            team: team,
                            members: const [], // Empty for now
                            onTap: () => _showTeamDetails(team),
                          )
                              .animate(
                                delay: Duration(milliseconds: index * 50),
                              )
                              .fadeIn(duration: 400.ms)
                              .slideY(
                                begin: 0.05,
                                end: 0,
                                duration: 400.ms,
                              );
                        },
                      ),
                    ),
    );
  }
}

/// Team details bottom sheet
class _TeamDetailsSheet extends StatelessWidget {
  final TeamModel team;
  final UserModel? leader;
  final VoidCallback onRequestToJoin;

  const _TeamDetailsSheet({
    required this.team,
    this.leader,
    required this.onRequestToJoin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team avatar and name
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
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
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.emoji_events_rounded,
                                size: 18,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                team.hackathonName ?? 'No hackathon',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Team info cards
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.people_rounded,
                            label: 'Members',
                            value:
                                '${team.memberIds.length}/${team.maxSize}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.event_available_rounded,
                            label: 'Open Slots',
                            value: '${team.availableSlots}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Leader info
                    if (leader != null) ...[
                      Text(
                        'Team Leader',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primaryBlue.withValues(alpha: 0.1),
                            backgroundImage: leader!.profileImageUrl != null
                                ? NetworkImage(leader!.profileImageUrl!)
                                : null,
                            child: leader!.profileImageUrl == null
                                ? Text(
                                    leader!.fullName.initials,
                                    style: const TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(leader!.fullName),
                          subtitle: Text(
                            '${leader!.role} • ${leader!.branch}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Description
                    if (team.description != null &&
                        team.description!.isNotEmpty) ...[
                      Text(
                        'About the Team',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        team.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
            // Join button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: team.isFull ? null : onRequestToJoin,
                  child: Text(
                    team.isFull ? 'Team is Full' : 'Request to Join',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Info card widget
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

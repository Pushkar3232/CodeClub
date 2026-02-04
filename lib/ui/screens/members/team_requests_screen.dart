import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
// Removed unused import: app_constants
import '../../../data/models/team_request_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/user_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/team_provider.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/user_card.dart';

/// Team requests screen showing incoming and outgoing requests
class TeamRequestsScreen extends StatefulWidget {
  const TeamRequestsScreen({super.key});

  @override
  State<TeamRequestsScreen> createState() => _TeamRequestsScreenState();
}

class _TeamRequestsScreenState extends State<TeamRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();
  Map<String, UserModel> _usersCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequestsData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadRequestsData() {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId != null) {
      final teamProvider = context.read<TeamProvider>();
      teamProvider.listenToIncomingRequests(userId);
      teamProvider.listenToOutgoingRequests(userId);
    }
  }

  Future<UserModel?> _getUser(String userId) async {
    if (_usersCache.containsKey(userId)) {
      return _usersCache[userId];
    }
    
    try {
      final user = await _userService.getUserById(userId);
      if (user != null) {
        _usersCache[userId] = user;
      }
      return user;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Incoming'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: Consumer<TeamProvider>(
        builder: (context, teamProvider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Incoming requests
              _buildRequestsList(
                requests: teamProvider.incomingRequests,
                isIncoming: true,
              ),
              // Outgoing requests
              _buildRequestsList(
                requests: teamProvider.outgoingRequests,
                isIncoming: false,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestsList({
    required List<TeamRequestModel> requests,
    required bool isIncoming,
  }) {
    if (requests.isEmpty) {
      return EmptyStateWidget(
        icon: isIncoming
            ? Icons.inbox_rounded
            : Icons.outbox_rounded,
        title: isIncoming
            ? 'No incoming requests'
            : 'No sent requests',
        subtitle: isIncoming
            ? 'When someone sends you a team request, it will appear here'
            : 'Requests you send to other members will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _RequestCard(
          request: request,
          isIncoming: isIncoming,
          getUserFn: _getUser,
        ).animate(delay: Duration(milliseconds: index * 50)).fadeIn(
              duration: 300.ms,
            ).slideX(
              begin: 0.05,
              end: 0,
              duration: 300.ms,
            );
      },
    );
  }
}

/// Request card widget
class _RequestCard extends StatefulWidget {
  final TeamRequestModel request;
  final bool isIncoming;
  final Future<UserModel?> Function(String) getUserFn;

  const _RequestCard({
    required this.request,
    required this.isIncoming,
    required this.getUserFn,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userId = widget.isIncoming
        ? widget.request.fromUserId
        : widget.request.toUserId;
    
    final user = await widget.getUserFn(userId);
    
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAccept() async {
    final teamProvider = context.read<TeamProvider>();
    final success = await teamProvider.acceptRequest(widget.request);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Request accepted!'
                : (teamProvider.errorMessage ?? 'Failed to accept request'),
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleReject() async {
    final teamProvider = context.read<TeamProvider>();
    final success = await teamProvider.rejectRequest(widget.request.id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Request rejected'
                : (teamProvider.errorMessage ?? 'Failed to reject request'),
          ),
          backgroundColor: success ? AppColors.warning : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const ShimmerUserCard();
    }

    if (_user == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(user: _user, radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user!.fullName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        '${_user!.role} • ${_user!.year}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Pending',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.request.message != null &&
                widget.request.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.request.message!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
            if (widget.isIncoming) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                      child: const Text('Accept'),
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
}

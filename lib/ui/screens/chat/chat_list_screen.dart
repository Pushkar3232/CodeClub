import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/user_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../widgets/loading_widgets.dart';
import 'chat_screen.dart';
import 'create_group_screen.dart';
import 'community_chat_screen.dart';

/// Chat list screen with tabs for different chat types
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  Map<String, UserModel> _usersCache = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadChats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadChats() {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId != null) {
      context.read<ChatProvider>().listenToChats(userId);
    }
  }

  Future<UserModel?> _getOtherUser(ChatModel chat, String currentUserId) async {
    final otherUserId = chat.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) return null;

    if (_usersCache.containsKey(otherUserId)) {
      return _usersCache[otherUserId];
    }

    try {
      final user = await _userService.getUserById(otherUserId);
      if (user != null) {
        _usersCache[otherUserId] = user;
      }
      return user;
    } catch (e) {
      return null;
    }
  }

  void _createNewGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );
  }

  void _openCommunity() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommunityChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Private', icon: Icon(Icons.person_outline)),
            Tab(text: 'Teams', icon: Icon(Icons.groups_outlined)),
            Tab(text: 'Groups', icon: Icon(Icons.group_outlined)),
            Tab(text: 'Community', icon: Icon(Icons.public_outlined)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _createNewGroup,
            icon: const Icon(Icons.group_add_outlined),
            tooltip: 'Create Group',
          ),
        ],
      ),
      body: Consumer2<AuthProvider, ChatProvider>(
        builder: (context, authProvider, chatProvider, _) {
          final currentUserId = authProvider.currentUserId;

          if (currentUserId == null) {
            return const EmptyStateWidget(
              icon: Icons.login_rounded,
              title: 'Not logged in',
              subtitle: 'Please log in to view your messages',
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Private Chats Tab
              _buildChatList(
                chats: chatProvider.privateChats,
                currentUserId: currentUserId,
                emptyIcon: Icons.chat_bubble_outline_rounded,
                emptyTitle: 'No private chats',
                emptySubtitle:
                    'Start a conversation by messaging a team member',
              ),
              // Team Chats Tab
              _buildChatList(
                chats: chatProvider.teamChats,
                currentUserId: currentUserId,
                emptyIcon: Icons.groups_outlined,
                emptyTitle: 'No team chats',
                emptySubtitle: 'Join or create a team to start chatting',
              ),
              // Group Chats Tab
              _buildChatList(
                chats: chatProvider.groupChats,
                currentUserId: currentUserId,
                emptyIcon: Icons.group_outlined,
                emptyTitle: 'No group chats',
                emptySubtitle: 'Create a group to chat with multiple people',
                showCreateButton: true,
                onCreatePressed: _createNewGroup,
              ),
              // Community Chats Tab
              _buildCommunityChatList(
                chats: chatProvider.communityChats,
                currentUserId: currentUserId,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChatList({
    required List<ChatModel> chats,
    required String currentUserId,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    bool showCreateButton = false,
    VoidCallback? onCreatePressed,
  }) {
    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmptyStateWidget(
              icon: emptyIcon,
              title: emptyTitle,
              subtitle: emptySubtitle,
            ),
            if (showCreateButton && onCreatePressed != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onCreatePressed,
                icon: const Icon(Icons.add),
                label: const Text('Create Group'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadChats();
      },
      child: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];

          return _ChatListItem(
                chat: chat,
                currentUserId: currentUserId,
                getUserFn: _getOtherUser,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chat.id,
                        title: chat.isGroupChat
                            ? (chat.groupName ?? 'Group Chat')
                            : '',
                        isGroupChat: chat.isGroupChat,
                      ),
                    ),
                  );
                },
              )
              .animate(delay: Duration(milliseconds: index * 50))
              .fadeIn(duration: 300.ms);
        },
      ),
    );
  }

  Widget _buildCommunityChatList({
    required List<ChatModel> chats,
    required String currentUserId,
  }) {
    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const EmptyStateWidget(
              icon: Icons.public_outlined,
              title: 'No community chats',
              subtitle: 'Be the first to create a community chat!',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openCommunity,
              icon: const Icon(Icons.add),
              label: const Text('Browse Communities'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadChats();
      },
      child: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];

          return _CommunityListItem(
                chat: chat,
                currentUserId: currentUserId,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chat.id,
                        title: chat.groupName ?? 'Community',
                        isGroupChat: true,
                      ),
                    ),
                  );
                },
              )
              .animate(delay: Duration(milliseconds: index * 50))
              .fadeIn(duration: 300.ms);
        },
      ),
    );
  }
}

/// Chat list item for private and group chats
class _ChatListItem extends StatefulWidget {
  final ChatModel chat;
  final String currentUserId;
  final Future<UserModel?> Function(ChatModel, String) getUserFn;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.chat,
    required this.currentUserId,
    required this.getUserFn,
    required this.onTap,
  });

  @override
  State<_ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<_ChatListItem> {
  UserModel? _otherUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!widget.chat.isGroupChat) {
      _loadUser();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadUser() async {
    final user = await widget.getUserFn(widget.chat, widget.currentUserId);
    if (mounted) {
      setState(() {
        _otherUser = user;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const ShimmerUserCard();
    }

    final displayName = widget.chat.isGroupChat
        ? (widget.chat.groupName ?? 'Group Chat')
        : (_otherUser?.fullName ?? 'Unknown');

    final initials = widget.chat.isGroupChat
        ? (widget.chat.groupName?.initials ?? 'GC')
        : (_otherUser?.fullName.initials ?? '?');

    IconData chatIcon;
    Color iconColor;

    switch (widget.chat.chatType) {
      case ChatType.team:
        chatIcon = Icons.groups_rounded;
        iconColor = AppColors.secondaryGreen;
        break;
      case ChatType.group:
        chatIcon = Icons.group_rounded;
        iconColor = AppColors.primaryBlue;
        break;
      case ChatType.community:
        chatIcon = Icons.public_rounded;
        iconColor = AppColors.accentOrange;
        break;
      default:
        chatIcon = Icons.person_rounded;
        iconColor = AppColors.primaryBlue;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: iconColor.withValues(alpha: 0.1),
        backgroundImage:
            !widget.chat.isGroupChat && _otherUser?.profileImageUrl != null
            ? NetworkImage(_otherUser!.profileImageUrl!)
            : null,
        child: !widget.chat.isGroupChat && _otherUser?.profileImageUrl != null
            ? null
            : widget.chat.isGroupChat
            ? Icon(chatIcon, color: iconColor)
            : Text(
                initials,
                style: TextStyle(color: iconColor, fontWeight: FontWeight.w600),
              ),
      ),
      title: Text(
        displayName,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              widget.chat.lastMessage ?? 'Start a conversation',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.chat.lastMessageAt != null)
            Text(
              widget.chat.lastMessageAt!.timeAgo,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontSize: 11,
              ),
            ),
        ],
      ),
      onTap: widget.onTap,
    );
  }
}

/// Community list item with join button
class _CommunityListItem extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;
  final VoidCallback onTap;

  const _CommunityListItem({
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isJoined = chat.participantIds.contains(currentUserId);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.accentOrange.withValues(alpha: 0.1),
        child: const Icon(Icons.public_rounded, color: AppColors.accentOrange),
      ),
      title: Text(
        chat.groupName ?? 'Community',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chat.groupDescription != null)
            Text(
              chat.groupDescription!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.people_outline,
                size: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 4),
              Text(
                '${chat.participantIds.length} members',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: isJoined
          ? const Icon(Icons.check_circle, color: AppColors.success)
          : TextButton(
              onPressed: () async {
                final chatProvider = context.read<ChatProvider>();
                await chatProvider.joinCommunityChat(chat.id, currentUserId);
              },
              child: const Text('Join'),
            ),
      onTap: onTap,
    );
  }
}

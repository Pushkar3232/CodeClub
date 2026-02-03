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

/// Chat list screen
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final UserService _userService = UserService();
  Map<String, UserModel> _usersCache = {};

  @override
  void initState() {
    super.initState();
    _loadChats();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
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

          final chats = chatProvider.chats;
          
          if (chats.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No messages yet',
              subtitle: 'Start a conversation by finding team members',
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
                              ? (chat.groupName ?? 'Team Chat')
                              : '',
                          isGroupChat: chat.isGroupChat,
                        ),
                      ),
                    );
                  },
                ).animate(delay: Duration(milliseconds: index * 50)).fadeIn(
                      duration: 300.ms,
                    );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Chat list item
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
        ? (widget.chat.groupName ?? 'Team Chat')
        : (_otherUser?.fullName ?? 'Unknown');
    
    final initials = widget.chat.isGroupChat
        ? (widget.chat.groupName?.initials ?? 'TC')
        : (_otherUser?.fullName.initials ?? '?');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: widget.chat.isGroupChat
            ? AppColors.secondaryGreen.withValues(alpha: 0.1)
            : AppColors.primaryBlue.withValues(alpha: 0.1),
        backgroundImage: !widget.chat.isGroupChat &&
                _otherUser?.profileImageUrl != null
            ? NetworkImage(_otherUser!.profileImageUrl!)
            : null,
        child: !widget.chat.isGroupChat &&
                _otherUser?.profileImageUrl != null
            ? null
            : widget.chat.isGroupChat
                ? const Icon(
                    Icons.groups_rounded,
                    color: AppColors.secondaryGreen,
                  )
                : Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
      ),
      title: Text(
        displayName,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
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

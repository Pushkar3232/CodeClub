import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/user_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';

/// Community Broadcast Chat Screen - All messages visible to all users
class CommunityBroadcastScreen extends StatefulWidget {
  final ChatModel community;

  const CommunityBroadcastScreen({
    super.key,
    required this.community,
  });

  @override
  State<CommunityBroadcastScreen> createState() => _CommunityBroadcastScreenState();
}

class _CommunityBroadcastScreenState extends State<CommunityBroadcastScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();

  Map<String, UserModel> _usersCache = {};
  bool _isLoadingUsers = false;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
      _loadCommunityData();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize notification service
  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      await _notificationService.requestPermission();
      print('Notifications initialized');
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> _loadCommunityData() async {
    final chatProvider = context.read<ChatProvider>();

    // Select the community chat and load messages
    await chatProvider.selectChat(widget.community);

    // Load all user details for this community
    _loadUsersForCommunity();
  }

  Future<void> _loadUsersForCommunity() async {
    setState(() => _isLoadingUsers = true);

    try {
      final users = await _userService.getUsersByIds(
        widget.community.participantIds,
      );
      setState(() {
        _usersCache = {for (var user in users) user.uid: user};
        _isLoadingUsers = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _sendMessage(String currentUserId) async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();

    _messageController.clear();

    final success = await chatProvider.sendMessage(
      senderId: currentUserId,
      content: message,
      type: MessageType.text,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _leaveCommunity(String currentUserId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Community'),
        content: const Text(
          'Are you sure you want to leave this community? You can always join again later.',
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

    if (confirmed == true && mounted) {
      final chatProvider = context.read<ChatProvider>();
      final success = await chatProvider.leaveCommunityChat(
        widget.community.id,
        currentUserId,
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You left the community'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.community.groupName ?? 'Community'),
            Text(
              '${widget.community.participantIds.length} members',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) => PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Members'),
                  onTap: () {
                    _showMembersDialog();
                  },
                ),
                PopupMenuItem(
                  child: const Text('Leave Community'),
                  onTap: () {
                    _leaveCommunity(authProvider.currentUserId ?? '');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer2<AuthProvider, ChatProvider>(
        builder: (context, authProvider, chatProvider, _) {
          final currentUserId = authProvider.currentUserId;

          if (currentUserId == null) {
            return const Center(
              child: Text('Please log in'),
            );
          }

          final messages = chatProvider.messages;

          // Show notification when new message arrives
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (messages.isNotEmpty && messages.length > _lastMessageCount) {
              final newMessage = messages.last;
              final isCurrentUser = newMessage.senderId == currentUserId;

              // Only show notification for messages from other users
              if (!isCurrentUser) {
                final senderUser = _usersCache[newMessage.senderId];
                final senderName = senderUser?.fullName ?? 'Unknown User';

                _notificationService.showMessageNotification(
                  chatId: widget.community.id,
                  senderName: senderName,
                  messageContent: newMessage.content,
                  senderImage: senderUser?.profileImageUrl,
                );
              }
              _lastMessageCount = messages.length;
            }
          });

          return Column(
            children: [
              // Description banner
              if (widget.community.groupDescription != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: AppColors.accentOrange.withValues(alpha: 0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About this community',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.community.groupDescription!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

              // Messages list
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.mail_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to share something!',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final senderUser = _usersCache[message.senderId];
                          final isCurrentUser =
                              message.senderId == currentUserId;

                          return _CommunityMessageBubble(
                            message: message,
                            senderUser: senderUser,
                            isCurrentUser: isCurrentUser,
                          )
                              .animate(delay: Duration(milliseconds: index * 10))
                              .fadeIn(duration: 300.ms)
                              .slideY(
                                begin: 0.1,
                                end: 0,
                                duration: 300.ms,
                              );
                        },
                      ),
              ),

              // Input area
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Message to all...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.emoji_emotions_outlined),
                            onPressed: () {
                              // Could implement emoji picker here
                            },
                          ),
                        ),
                        maxLines: null,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) =>
                            _sendMessage(currentUserId),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      mini: true,
                      onPressed: () => _sendMessage(currentUserId),
                      backgroundColor: AppColors.accentOrange,
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMembersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Community Members'),
        content: SizedBox(
          width: double.maxFinite,
          child: _isLoadingUsers
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : ListView.builder(
                  itemCount: widget.community.participantIds.length,
                  itemBuilder: (context, index) {
                    final userId = widget.community.participantIds[index];
                    final user = _usersCache[userId];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user?.profileImageUrl != null
                            ? NetworkImage(user!.profileImageUrl!)
                            : null,
                        child: user?.profileImageUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(user?.fullName ?? 'Unknown User'),
                      subtitle: Text(user?.branch ?? ''),
                      trailing: widget.community.createdBy == userId
                          ? const Chip(
                              label: Text('Admin'),
                              backgroundColor:
                                  AppColors.accentOrange,
                            )
                          : null,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Community Message Bubble Widget
class _CommunityMessageBubble extends StatelessWidget {
  final MessageModel message;
  final UserModel? senderUser;
  final bool isCurrentUser;

  const _CommunityMessageBubble({
    required this.message,
    required this.senderUser,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Sender info (only for non-current user messages)
          if (!isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: senderUser?.profileImageUrl != null
                        ? NetworkImage(senderUser!.profileImageUrl!)
                        : null,
                    child: senderUser?.profileImageUrl == null
                        ? const Icon(Icons.person, size: 12)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    senderUser?.fullName ?? 'Unknown',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          // Message bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? AppColors.accentOrange
                  : (isDark
                      ? Colors.grey[800]
                      : Colors.grey[200]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: isCurrentUser
                    ? Colors.white
                    : (isDark
                        ? Colors.white
                        : Colors.black87),
              ),
            ),
          ),
          // Time
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
            child: Text(
              _formatTime(message.createdAt),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

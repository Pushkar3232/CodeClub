import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/chat_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../widgets/loading_widgets.dart';
import 'chat_screen.dart';

/// Community chat screen - shows all community chats and allows creating new ones
class CommunityChatScreen extends StatefulWidget {
  const CommunityChatScreen({super.key});

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadCommunityChats();
    });
  }

  void _createCommunity() {
    showDialog(
      context: context,
      builder: (context) => const _CreateCommunityDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            onPressed: _createCommunity,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create Community',
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
              subtitle: 'Please log in to view communities',
            );
          }

          final communities = chatProvider.communityChats;

          if (communities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const EmptyStateWidget(
                    icon: Icons.public_outlined,
                    title: 'No communities yet',
                    subtitle: 'Be the first to create a community chat!',
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _createCommunity,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Community'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ChatProvider>().loadCommunityChats();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: communities.length,
              itemBuilder: (context, index) {
                final community = communities[index];
                final isJoined = community.participantIds.contains(
                  currentUserId,
                );

                return _CommunityCard(
                      community: community,
                      isJoined: isJoined,
                      currentUserId: currentUserId,
                      onTap: () {
                        if (isJoined) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatId: community.id,
                                title: community.groupName ?? 'Community',
                                isGroupChat: true,
                              ),
                            ),
                          );
                        }
                      },
                    )
                    .animate(delay: Duration(milliseconds: index * 50))
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.1, end: 0, duration: 300.ms);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCommunity,
        icon: const Icon(Icons.add),
        label: const Text('Create'),
        backgroundColor: AppColors.accentOrange,
      ),
    );
  }
}

/// Community card widget
class _CommunityCard extends StatelessWidget {
  final ChatModel community;
  final bool isJoined;
  final String currentUserId;
  final VoidCallback onTap;

  const _CommunityCard({
    required this.community,
    required this.isJoined,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isJoined ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Community Avatar
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.accentOrange.withValues(alpha: 0.1),
                backgroundImage: community.groupImageUrl != null
                    ? NetworkImage(community.groupImageUrl!)
                    : null,
                child: community.groupImageUrl == null
                    ? const Icon(
                        Icons.public_rounded,
                        color: AppColors.accentOrange,
                        size: 32,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Community Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.groupName ?? 'Community',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (community.groupDescription != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        community.groupDescription!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 16,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${community.participantIds.length} members',
                          style: Theme.of(context).textTheme.bodySmall
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
              // Join/Open Button
              if (isJoined)
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  child: const Text('Open'),
                )
              else
                ElevatedButton(
                  onPressed: () async {
                    final chatProvider = context.read<ChatProvider>();
                    final success = await chatProvider.joinCommunityChat(
                      community.id,
                      currentUserId,
                    );
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Joined community!'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('Join'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog to create a new community
class _CreateCommunityDialog extends StatefulWidget {
  const _CreateCommunityDialog();

  @override
  State<_CreateCommunityDialog> createState() => _CreateCommunityDialogState();
}

class _CreateCommunityDialogState extends State<_CreateCommunityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createCommunity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final userId = authProvider.currentUserId;

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final chat = await chatProvider.createCommunityChat(
      name: _nameController.text.trim(),
      creatorId: userId,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
    );

    setState(() => _isLoading = false);

    if (chat != null && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Community created successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navigate to the new community chat
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Community'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Community Name',
                hintText: 'Enter community name',
                prefixIcon: Icon(Icons.public),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a community name';
                }
                if (value.trim().length < 3) {
                  return 'Name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'What is this community about?',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createCommunity,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/user_service.dart';

/// Chat provider for managing chat state
class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();

  List<ChatModel> _chats = [];
  ChatModel? _currentChat;
  List<MessageModel> _messages = [];
  Map<String, UserModel> _chatUsers = {};
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _chatsSubscription;

  // Getters
  List<ChatModel> get chats => _chats;
  ChatModel? get currentChat => _currentChat;
  List<MessageModel> get messages => _messages;
  Map<String, UserModel> get chatUsers => _chatUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load user's chats
  void loadUserChats(String userId) {
    _chatsSubscription?.cancel();
    _chatsSubscription = _chatService.getUserChats(userId).listen(
      (chats) async {
        _chats = chats;
        
        // Load user details for each chat
        final userIds = <String>{};
        for (final chat in chats) {
          userIds.addAll(chat.participantIds);
        }
        
        if (userIds.isNotEmpty) {
          final users = await _userService.getUsersByIds(userIds.toList());
          _chatUsers = {for (var user in users) user.uid: user};
        }
        
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  /// Listen to user chats
  void listenToChats(String userId) {
    loadUserChats(userId);
  }

  /// Get messages stream for a chat
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _chatService.getMessagesStream(chatId);
  }

  /// Get or create team chat
  Future<ChatModel?> getOrCreateTeamChat(String teamId, String teamName) async {
    try {
      return await _chatService.getOrCreateTeamChat(teamId, teamName);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  /// Open chat with user
  Future<ChatModel?> openChatWithUser(String currentUserId, String otherUserId) async {
    try {
      return await _chatService.getOrCreatePrivateChat(currentUserId, otherUserId);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  /// Open team chat
  Future<ChatModel?> openTeamChat({
    required String teamId,
    required String groupName,
    required List<String> memberIds,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final chat = await _chatService.createTeamChat(
        teamId: teamId,
        groupName: groupName,
        memberIds: memberIds,
      );
      await selectChat(chat);
      _isLoading = false;
      notifyListeners();
      return chat;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Select a chat and load messages
  Future<void> selectChat(ChatModel chat) async {
    _currentChat = chat;
    _messages = [];
    notifyListeners();

    // Load users for this chat
    final users = await _userService.getUsersByIds(chat.participantIds);
    for (final user in users) {
      _chatUsers[user.uid] = user;
    }

    // Subscribe to messages
    _messagesSubscription?.cancel();
    _messagesSubscription = _chatService.getMessages(chat.id).listen(
      (messages) {
        _messages = messages;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  /// Send a message
  Future<bool> sendMessage({
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    if (_currentChat == null || content.trim().isEmpty) return false;

    try {
      await _chatService.sendMessage(
        chatId: _currentChat!.id,
        senderId: senderId,
        content: content.trim(),
        type: type,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String userId) async {
    if (_currentChat == null) return;
    
    try {
      await _chatService.markAllMessagesAsRead(_currentChat!.id, userId);
    } catch (e) {
      // Silent error handling
    }
  }

  /// Close current chat
  void closeChat() {
    _messagesSubscription?.cancel();
    _currentChat = null;
    _messages = [];
    notifyListeners();
  }

  /// Get user for chat display
  UserModel? getUserForChat(ChatModel chat, String currentUserId) {
    if (chat.isGroupChat) return null;
    final otherUserId = chat.getOtherParticipantId(currentUserId);
    return _chatUsers[otherUserId];
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _chatsSubscription?.cancel();
    super.dispose();
  }
}

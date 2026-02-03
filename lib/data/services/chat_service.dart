import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

/// Chat service for CodeClub
/// Handles all chat-related Firestore operations
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection references
  CollectionReference<Map<String, dynamic>> get _chatsCollection =>
      _firestore.collection('chats');

  CollectionReference<Map<String, dynamic>> _messagesCollection(String chatId) =>
      _chatsCollection.doc(chatId).collection('messages');

  // ==================== CHAT OPERATIONS ====================

  /// Get or create a one-on-one chat between two users
  Future<ChatModel> getOrCreateChat(String userId1, String userId2) async {
    try {
      // Check if chat already exists
      final existingChat = await _chatsCollection
          .where('participantIds', arrayContains: userId1)
          .where('isGroupChat', isEqualTo: false)
          .get();

      for (final doc in existingChat.docs) {
        final chat = ChatModel.fromFirestore(doc);
        if (chat.participantIds.contains(userId2)) {
          return chat;
        }
      }

      // Create new chat
      final chatDoc = _chatsCollection.doc();
      final chat = ChatModel(
        id: chatDoc.id,
        participantIds: [userId1, userId2],
        createdAt: DateTime.now(),
        isGroupChat: false,
      );

      await chatDoc.set(chat.toFirestore());
      return chat;
    } catch (e) {
      rethrow;
    }
  }

  /// Create a team group chat
  Future<ChatModel> createTeamChat({
    required String teamId,
    required String groupName,
    required List<String> memberIds,
  }) async {
    try {
      // Check if team chat already exists
      final existingChat = await _chatsCollection
          .where('teamId', isEqualTo: teamId)
          .get();

      if (existingChat.docs.isNotEmpty) {
        return ChatModel.fromFirestore(existingChat.docs.first);
      }

      // Create new team chat
      final chatDoc = _chatsCollection.doc();
      final chat = ChatModel(
        id: chatDoc.id,
        participantIds: memberIds,
        teamId: teamId,
        createdAt: DateTime.now(),
        isGroupChat: true,
        groupName: groupName,
      );

      await chatDoc.set(chat.toFirestore());
      return chat;
    } catch (e) {
      rethrow;
    }
  }

  /// Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final doc = await _chatsCollection.doc(chatId).get();
      if (doc.exists) {
        return ChatModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get team chat
  Future<ChatModel?> getTeamChat(String teamId) async {
    try {
      final snapshot = await _chatsCollection
          .where('teamId', isEqualTo: teamId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ChatModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all chats for a user
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _chatsCollection
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromFirestore(doc))
            .toList());
  }

  /// Update chat participants (for group chats)
  Future<void> updateChatParticipants(
    String chatId,
    List<String> participantIds,
  ) async {
    try {
      await _chatsCollection.doc(chatId).update({
        'participantIds': participantIds,
      });
    } catch (e) {
      rethrow;
    }
  }

  // ==================== MESSAGE OPERATIONS ====================

  /// Send a message
  Future<MessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    try {
      final messageDoc = _messagesCollection(chatId).doc();
      final message = MessageModel(
        id: messageDoc.id,
        chatId: chatId,
        senderId: senderId,
        content: content,
        type: type,
        createdAt: DateTime.now(),
        readBy: [senderId],
      );

      // Send message
      await messageDoc.set(message.toFirestore());

      // Update chat's last message
      await _chatsCollection.doc(chatId).update({
        'lastMessage': content,
        'lastMessageSenderId': senderId,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      return message;
    } catch (e) {
      rethrow;
    }
  }

  /// Get messages for a chat
  Stream<List<MessageModel>> getMessages(String chatId, {int limit = 50}) {
    return _messagesCollection(chatId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList()
            .reversed
            .toList());
  }

  /// Load more messages (for pagination)
  Future<List<MessageModel>> loadMoreMessages(
    String chatId, {
    required DateTime beforeTime,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _messagesCollection(chatId)
          .orderBy('createdAt', descending: true)
          .where('createdAt', isLessThan: Timestamp.fromDate(beforeTime))
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String chatId, String messageId, String userId) async {
    try {
      await _messagesCollection(chatId).doc(messageId).update({
        'isRead': true,
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Mark all messages in chat as read
  Future<void> markAllMessagesAsRead(String chatId, String userId) async {
    try {
      final unreadMessages = await _messagesCollection(chatId)
          .where('senderId', isNotEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readBy': FieldValue.arrayUnion([userId]),
        });
      }
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _messagesCollection(chatId).doc(messageId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread message count for a chat
  Future<int> getUnreadCount(String chatId, String userId) async {
    try {
      final snapshot = await _messagesCollection(chatId)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get messages stream for a chat
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  /// Get or create team chat
  Future<ChatModel> getOrCreateTeamChat(String teamId, String teamName) async {
    // Check if team chat already exists
    final existingChat = await _firestore
        .collection('chats')
        .where('teamId', isEqualTo: teamId)
        .where('isGroupChat', isEqualTo: true)
        .get();
    
    if (existingChat.docs.isNotEmpty) {
      return ChatModel.fromFirestore(existingChat.docs.first);
    }
    
    // Create new team chat
    final chatData = ChatModel(
      id: '',
      participantIds: [], // Will be populated when members join
      teamId: teamId,
      createdAt: DateTime.now(),
      isGroupChat: true,
      groupName: teamName,
    );
    
    final docRef = await _firestore
        .collection('chats')
        .add(chatData.toFirestore());
    
    return ChatModel(
      id: docRef.id,
      participantIds: chatData.participantIds,
      teamId: chatData.teamId,
      createdAt: chatData.createdAt,
      isGroupChat: chatData.isGroupChat,
      groupName: chatData.groupName,
    );
  }

  /// Get or create private chat
  Future<ChatModel> getOrCreatePrivateChat(String user1Id, String user2Id) async {
    // Check if chat already exists
    final existingChat = await _firestore
        .collection('chats')
        .where('participantIds', arrayContains: user1Id)
        .where('isGroupChat', isEqualTo: false)
        .get();
    
    for (final doc in existingChat.docs) {
      final chat = ChatModel.fromFirestore(doc);
      if (chat.participantIds.contains(user2Id)) {
        return chat;
      }
    }
    
    // Create new private chat
    final chatData = ChatModel(
      id: '',
      participantIds: [user1Id, user2Id],
      createdAt: DateTime.now(),
      isGroupChat: false,
    );
    
    final docRef = await _firestore
        .collection('chats')
        .add(chatData.toFirestore());
    
    return ChatModel(
      id: docRef.id,
      participantIds: chatData.participantIds,
      createdAt: chatData.createdAt,
      isGroupChat: chatData.isGroupChat,
    );
  }
}

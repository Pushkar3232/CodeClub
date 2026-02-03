import 'package:cloud_firestore/cloud_firestore.dart';

/// Chat/Conversation model for CodeClub
class ChatModel {
  final String id;
  final DateTime? lastMessageAt;
  final List<String> participantIds;
  final String? teamId; // If it's a team chat
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTime;
  final DateTime createdAt;
  final bool isGroupChat;
  final String? groupName; // For team chats

  ChatModel({
    required this.id,
    required this.participantIds,
    this.teamId,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageTime,
    this.lastMessageAt,
    required this.createdAt,
    this.isGroupChat = false,
    this.groupName,
  });

  /// Create from Firestore document
  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      teamId: data['teamId'],
      lastMessage: data['lastMessage'],
      lastMessageSenderId: data['lastMessageSenderId'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),      lastMessageAt: data['lastMessageAt']?.toDate(),      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isGroupChat: data['isGroupChat'] ?? false,
      groupName: data['groupName'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'participantIds': participantIds,
      'teamId': teamId,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime != null 
          ? Timestamp.fromDate(lastMessageTime!) 
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'isGroupChat': isGroupChat,
      'groupName': groupName,
    };
  }

  /// Copy with modifications
  ChatModel copyWith({
    String? id,
    List<String>? participantIds,
    String? teamId,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    DateTime? createdAt,
    bool? isGroupChat,
    String? groupName,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      teamId: teamId ?? this.teamId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      createdAt: createdAt ?? this.createdAt,
      isGroupChat: isGroupChat ?? this.isGroupChat,
      groupName: groupName ?? this.groupName,
    );
  }

  /// Get other participant ID (for 1-1 chats)
  String getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  @override
  String toString() {
    return 'ChatModel(id: $id, participants: ${participantIds.length}, isGroup: $isGroupChat)';
  }
}

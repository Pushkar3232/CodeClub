import 'package:cloud_firestore/cloud_firestore.dart';

/// Team model for CodeClub
class TeamModel {
  final String id;
  final String name;
  final String? hackathonName;
  final String leaderId;
  final List<String> memberIds;
  final int maxSize;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isOpen; // Accepting new members

  TeamModel({
    required this.id,
    required this.name,
    this.hackathonName,
    required this.leaderId,
    required this.memberIds,
    required this.maxSize,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.isOpen = true,
  });

  /// Create from Firestore document
  factory TeamModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamModel(
      id: doc.id,
      name: data['name'] ?? '',
      hackathonName: data['hackathonName'],
      leaderId: data['leaderId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      maxSize: data['maxSize'] ?? 4,
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOpen: data['isOpen'] ?? true,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'hackathonName': hackathonName,
      'leaderId': leaderId,
      'memberIds': memberIds,
      'maxSize': maxSize,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'isOpen': isOpen,
    };
  }

  /// Copy with modifications
  TeamModel copyWith({
    String? id,
    String? name,
    String? hackathonName,
    String? leaderId,
    List<String>? memberIds,
    int? maxSize,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOpen,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      hackathonName: hackathonName ?? this.hackathonName,
      leaderId: leaderId ?? this.leaderId,
      memberIds: memberIds ?? this.memberIds,
      maxSize: maxSize ?? this.maxSize,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOpen: isOpen ?? this.isOpen,
    );
  }

  /// Check if team is full
  bool get isFull => memberIds.length >= maxSize;

  /// Get available slots
  int get availableSlots => maxSize - memberIds.length;

  /// Check if user is member
  bool isMember(String userId) => memberIds.contains(userId);

  /// Check if user is leader
  bool isLeader(String userId) => leaderId == userId;

  @override
  String toString() {
    return 'TeamModel(id: $id, name: $name, members: ${memberIds.length}/$maxSize)';
  }
}

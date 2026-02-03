import 'package:cloud_firestore/cloud_firestore.dart';

/// Team request status enum
enum TeamRequestStatus { pending, accepted, rejected }

/// Team request model for CodeClub
class TeamRequestModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String? teamId;
  final String? message;
  final TeamRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeamRequestModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    this.teamId,
    this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory TeamRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamRequestModel(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      teamId: data['teamId'],
      message: data['message'],
      status: TeamRequestStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => TeamRequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'teamId': teamId,
      'message': message,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  /// Copy with modifications
  TeamRequestModel copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? teamId,
    String? message,
    TeamRequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamRequestModel(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      teamId: teamId ?? this.teamId,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if request is pending
  bool get isPending => status == TeamRequestStatus.pending;

  /// Check if request is accepted
  bool get isAccepted => status == TeamRequestStatus.accepted;

  /// Check if request is rejected
  bool get isRejected => status == TeamRequestStatus.rejected;

  @override
  String toString() {
    return 'TeamRequestModel(id: $id, from: $fromUserId, to: $toUserId, status: $status)';
  }
}

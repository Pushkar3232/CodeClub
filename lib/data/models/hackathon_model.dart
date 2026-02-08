import 'package:cloud_firestore/cloud_firestore.dart';

/// Hackathon model for CodeClub
class HackathonModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime registrationDeadline;
  final int minTeamSize;
  final int maxTeamSize;
  final String venue;
  final String? website;
  final List<String> prizes;
  final List<String> registeredTeamIds;
  final List<String> registeredIndividualIds;
  final bool isActive;
  final DateTime createdAt;
  final List<String>? rules;
  final String? createdBy;

  HackathonModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.registrationDeadline,
    this.minTeamSize = 1,
    this.maxTeamSize = 4,
    required this.venue,
    this.website,
    this.prizes = const [],
    this.registeredTeamIds = const [],
    this.registeredIndividualIds = const [],
    this.isActive = true,
    required this.createdAt,
    this.rules,
    this.createdBy,
  });

  /// Create from Firestore document
  factory HackathonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HackathonModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      registrationDeadline: (data['registrationDeadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      minTeamSize: data['minTeamSize'] ?? 1,
      maxTeamSize: data['maxTeamSize'] ?? 4,
      venue: data['venue'] ?? '',
      website: data['website'],
      prizes: (data['prizes'] as List<dynamic>?)?.cast<String>() ?? [],
      registeredTeamIds: (data['registeredTeamIds'] as List<dynamic>?)?.cast<String>() ?? [],
      registeredIndividualIds: (data['registeredIndividualIds'] as List<dynamic>?)?.cast<String>() ?? [],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rules: (data['rules'] as List<dynamic>?)?.cast<String>(),
      createdBy: data['createdBy'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'registrationDeadline': Timestamp.fromDate(registrationDeadline),
      'minTeamSize': minTeamSize,
      'maxTeamSize': maxTeamSize,
      'venue': venue,
      'website': website,
      'prizes': prizes,
      'registeredTeamIds': registeredTeamIds,
      'registeredIndividualIds': registeredIndividualIds,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'rules': rules,
      'createdBy': createdBy,
    };
  }

  /// Copy with modifications
  HackathonModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationDeadline,
    int? minTeamSize,
    int? maxTeamSize,
    String? venue,
    String? website,
    List<String>? prizes,
    List<String>? registeredTeamIds,
    List<String>? registeredIndividualIds,
    bool? isActive,
    DateTime? createdAt,
    List<String>? rules,
    String? createdBy,
  }) {
    return HackathonModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      minTeamSize: minTeamSize ?? this.minTeamSize,
      maxTeamSize: maxTeamSize ?? this.maxTeamSize,
      venue: venue ?? this.venue,
      website: website ?? this.website,
      prizes: prizes ?? this.prizes,
      registeredTeamIds: registeredTeamIds ?? this.registeredTeamIds,
      registeredIndividualIds: registeredIndividualIds ?? this.registeredIndividualIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      rules: rules ?? this.rules,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Check if registration is open
  bool get isRegistrationOpen => DateTime.now().isBefore(registrationDeadline);

  /// Check if hackathon is upcoming
  bool get isUpcoming => DateTime.now().isBefore(startDate);

  /// Check if hackathon is ongoing
  bool get isOngoing => 
      DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);

  /// Check if hackathon has ended
  bool get hasEnded => DateTime.now().isAfter(endDate);

  /// Get total registrations count
  int get totalRegistrations => 
      registeredTeamIds.length + registeredIndividualIds.length;

  /// Check if user is registered
  bool isUserRegistered(String userId) => 
      registeredIndividualIds.contains(userId);

  /// Check if team is registered
  bool isTeamRegistered(String teamId) => 
      registeredTeamIds.contains(teamId);

  @override
  String toString() {
    return 'HackathonModel(id: $id, title: $title, registrations: $totalRegistrations)';
  }
}

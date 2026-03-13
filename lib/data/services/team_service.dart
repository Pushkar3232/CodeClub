import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';
import '../models/team_request_model.dart';
import 'chat_service.dart';
import 'user_service.dart';

/// Team service for CodeClub
/// Handles all team-related Firestore operations
class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();

  /// Collection references
  CollectionReference<Map<String, dynamic>> get _teamsCollection =>
      _firestore.collection('teams');

  CollectionReference<Map<String, dynamic>> get _requestsCollection =>
      _firestore.collection('team_requests');

  // ==================== TEAM OPERATIONS ====================

  /// Create a new team
  Future<TeamModel> createTeam({
    required String name,
    required String leaderId,
    String? hackathonName,
    String? description,
    int maxSize = 4,
  }) async {
    try {
      final doc = _teamsCollection.doc();
      final now = DateTime.now();

      final team = TeamModel(
        id: doc.id,
        name: name,
        hackathonName: hackathonName,
        leaderId: leaderId,
        memberIds: [leaderId], // Leader is automatically a member
        maxSize: maxSize,
        description: description,
        createdAt: now,
        updatedAt: now,
        isOpen: true,
      );

      await doc.set(team.toFirestore());
      
      // Update user's current team
      await _userService.updateUserTeam(leaderId, doc.id);

      // Ensure each team has a dedicated team chat from day one.
      await _chatService.createTeamChat(
        teamId: doc.id,
        groupName: name,
        memberIds: [leaderId],
      );

      return team;
    } catch (e) {
      rethrow;
    }
  }

  /// Get team by ID
  Future<TeamModel?> getTeamById(String teamId) async {
    try {
      final doc = await _teamsCollection.doc(teamId).get();
      if (doc.exists) {
        return TeamModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get team stream
  Stream<TeamModel?> getTeamStream(String teamId) {
    return _teamsCollection.doc(teamId).snapshots().map(
          (doc) => doc.exists ? TeamModel.fromFirestore(doc) : null,
        );
  }

  /// Get user's current team
  Future<TeamModel?> getUserTeam(String? teamId) async {
    if (teamId == null) return null;
    return getTeamById(teamId);
  }

  /// Get all teams (open for joining)
  Future<List<TeamModel>> getOpenTeams() async {
    try {
      final snapshot = await _teamsCollection
          .where('isOpen', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TeamModel.fromFirestore(doc))
          .where((team) => !team.isFull)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Add member to team
  Future<void> addMemberToTeam(String teamId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final teamDoc = await transaction.get(_teamsCollection.doc(teamId));
        
        if (!teamDoc.exists) {
          throw Exception('Team not found');
        }
        
        final team = TeamModel.fromFirestore(teamDoc);
        
        if (team.isFull) {
          throw Exception('Team is full');
        }
        
        if (team.isMember(userId)) {
          throw Exception('User is already a member');
        }
        
        final updatedMembers = [...team.memberIds, userId];
        
        transaction.update(_teamsCollection.doc(teamId), {
          'memberIds': updatedMembers,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      
      // Update user's current team
      await _userService.updateUserTeam(userId, teamId);

      await _syncTeamChatParticipants(teamId);
    } catch (e) {
      rethrow;
    }
  }

  /// Remove member from team
  Future<void> removeMemberFromTeam(String teamId, String userId) async {
    try {
      final team = await getTeamById(teamId);
      
      if (team == null) throw Exception('Team not found');
      if (team.isLeader(userId)) throw Exception('Leader cannot leave the team');
      
      final updatedMembers = team.memberIds.where((id) => id != userId).toList();
      
      await _teamsCollection.doc(teamId).update({
        'memberIds': updatedMembers,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Remove team from user
      await _userService.updateUserTeam(userId, null);

      await _syncTeamChatParticipants(teamId);
    } catch (e) {
      rethrow;
    }
  }

  /// Update team details
  Future<void> updateTeam(TeamModel team) async {
    try {
      await _teamsCollection.doc(team.id).update(team.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  /// Delete team
  Future<void> deleteTeam(String teamId) async {
    try {
      final team = await getTeamById(teamId);
      
      if (team != null) {
        // Remove team from all members
        for (final memberId in team.memberIds) {
          await _userService.updateUserTeam(memberId, null);
        }
      }
      
      await _teamsCollection.doc(teamId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== TEAM REQUEST OPERATIONS ====================

  /// Send team request
  Future<TeamRequestModel> sendTeamRequest({
    required String fromUserId,
    required String toUserId,
    String? teamId,
    String? message,
  }) async {
    try {
      // Check if request already exists
      final existingRequest = await _requestsCollection
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        throw Exception('Request already sent');
      }

      final doc = _requestsCollection.doc();
      final now = DateTime.now();

      final request = TeamRequestModel(
        id: doc.id,
        fromUserId: fromUserId,
        toUserId: toUserId,
        teamId: teamId,
        message: message,
        status: TeamRequestStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      await doc.set(request.toFirestore());

      return request;
    } catch (e) {
      rethrow;
    }
  }

  /// Get incoming requests for user
  Stream<List<TeamRequestModel>> getIncomingRequests(String userId) {
    return _requestsCollection
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TeamRequestModel.fromFirestore(doc))
            .toList());
  }

  /// Get outgoing requests from user
  Stream<List<TeamRequestModel>> getOutgoingRequests(String userId) {
    return _requestsCollection
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TeamRequestModel.fromFirestore(doc))
            .toList());
  }

  /// Accept team request
  Future<void> acceptRequest(TeamRequestModel request) async {
    try {
      await _requestsCollection.doc(request.id).update({
        'status': TeamRequestStatus.accepted.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If there's a team, add user to team
      if (request.teamId != null) {
        await addMemberToTeam(request.teamId!, request.toUserId);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Reject team request
  Future<void> rejectRequest(String requestId) async {
    try {
      await _requestsCollection.doc(requestId).update({
        'status': TeamRequestStatus.rejected.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel team request
  Future<void> cancelRequest(String requestId) async {
    try {
      await _requestsCollection.doc(requestId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _syncTeamChatParticipants(String teamId) async {
    final team = await getTeamById(teamId);
    if (team == null) {
      return;
    }

    final teamChat = await _chatService.getTeamChat(teamId);
    if (teamChat == null) {
      await _chatService.createTeamChat(
        teamId: teamId,
        groupName: team.name,
        memberIds: team.memberIds,
      );
      return;
    }

    await _chatService.updateChatParticipants(teamChat.id, team.memberIds);
  }
}

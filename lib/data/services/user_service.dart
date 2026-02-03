import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// User service for CodeClub
/// Handles all user-related Firestore operations
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user stream
  Stream<UserModel?> getUserStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromFirestore(doc) : null,
        );
  }

  /// Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).update(user.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  /// Get all users (for finding team members)
  Future<List<UserModel>> getAllUsers({
    String? excludeUserId,
    List<String>? excludeUserIds,
  }) async {
    try {
      final query = _usersCollection
          .where('isProfileComplete', isEqualTo: true);
      
      final snapshot = await query.get();
      
      final excludeIds = <String>{};
      if (excludeUserId != null) excludeIds.add(excludeUserId);
      if (excludeUserIds != null) excludeIds.addAll(excludeUserIds);
      
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => !excludeIds.contains(user.uid))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Search users by name or skill
  Future<List<UserModel>> searchUsers({
    String? query,
    String? skill,
    String? role,
    String? year,
    String? excludeUserId,
  }) async {
    try {
      // Get all users first, then filter in memory
      // This is a simple approach; for production, consider using Algolia or similar
      final users = await getAllUsers(excludeUserId: excludeUserId);
      
      return users.where((user) {
        // Filter by query (name search)
        if (query != null && query.isNotEmpty) {
          if (!user.fullName.toLowerCase().contains(query.toLowerCase())) {
            return false;
          }
        }
        
        // Filter by skill
        if (skill != null && skill.isNotEmpty) {
          if (!user.skills.any((s) => s.toLowerCase() == skill.toLowerCase())) {
            return false;
          }
        }
        
        // Filter by role
        if (role != null && role.isNotEmpty) {
          if (user.role.toLowerCase() != role.toLowerCase()) {
            return false;
          }
        }
        
        // Filter by year
        if (year != null && year.isNotEmpty) {
          if (user.year.toLowerCase() != year.toLowerCase()) {
            return false;
          }
        }
        
        return true;
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get users by IDs
  Future<List<UserModel>> getUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];
    
    try {
      final users = <UserModel>[];
      
      // Firestore 'whereIn' has a limit of 10 items
      // So we batch the requests
      for (var i = 0; i < uids.length; i += 10) {
        final batch = uids.sublist(
          i,
          i + 10 > uids.length ? uids.length : i + 10,
        );
        
        final snapshot = await _usersCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        users.addAll(
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)),
        );
      }
      
      return users;
    } catch (e) {
      rethrow;
    }
  }

  /// Update user's current team
  Future<void> updateUserTeam(String uid, String? teamId) async {
    try {
      await _usersCollection.doc(uid).update({
        'currentTeamId': teamId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
}

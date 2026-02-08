import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/application_model.dart';
import '../models/hackathon_model.dart';
import '../models/user_model.dart';
import '../models/team_model.dart';

/// Admin service for CodeClub
/// Handles all admin-related Firestore operations
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _hackathonsCollection =>
      _firestore.collection('hackathons');

  CollectionReference<Map<String, dynamic>> get _applicationsCollection =>
      _firestore.collection('applications');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _teamsCollection =>
      _firestore.collection('teams');

  // ==================== HACKATHON CRUD ====================

  /// Create a new hackathon
  Future<HackathonModel> createHackathon(HackathonModel hackathon) async {
    try {
      final doc = _hackathonsCollection.doc();
      final newHackathon = hackathon.copyWith(id: doc.id);
      await doc.set(newHackathon.toFirestore());
      return newHackathon;
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing hackathon
  Future<void> updateHackathon(HackathonModel hackathon) async {
    try {
      await _hackathonsCollection
          .doc(hackathon.id)
          .update(hackathon.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a hackathon and its applications
  Future<void> deleteHackathon(String hackathonId) async {
    try {
      // Delete related applications
      final apps = await _applicationsCollection
          .where('hackathonId', isEqualTo: hackathonId)
          .get();
      final batch = _firestore.batch();
      for (final doc in apps.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_hackathonsCollection.doc(hackathonId));
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Get all hackathons (including inactive, for admin view)
  Future<List<HackathonModel>> getAllHackathonsAdmin() async {
    try {
      final snapshot = await _hackathonsCollection
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => HackathonModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== APPLICATION MANAGEMENT ====================

  /// Get all applications (admin view)
  Future<List<ApplicationModel>> getAllApplications() async {
    try {
      final snapshot = await _applicationsCollection
          .orderBy('appliedAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => ApplicationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get applications for a specific hackathon
  Future<List<ApplicationModel>> getApplicationsForHackathon(
      String hackathonId) async {
    try {
      final snapshot = await _applicationsCollection
          .where('hackathonId', isEqualTo: hackathonId)
          .orderBy('appliedAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => ApplicationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Approve an application
  Future<void> approveApplication(
      String applicationId, String adminUid) async {
    try {
      await _applicationsCollection.doc(applicationId).update({
        'status': 'approved',
        'reviewedAt': Timestamp.now(),
        'reviewedBy': adminUid,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Reject an application
  Future<void> rejectApplication(
      String applicationId, String adminUid, {String? remarks}) async {
    try {
      await _applicationsCollection.doc(applicationId).update({
        'status': 'rejected',
        'reviewedAt': Timestamp.now(),
        'reviewedBy': adminUid,
        'remarks': remarks,
      });
    } catch (e) {
      rethrow;
    }
  }

  // ==================== STUDENT APPLICATION ====================

  /// Submit an application (used by students)
  Future<ApplicationModel> submitApplication(
      ApplicationModel application) async {
    try {
      // Check if already applied
      final existing = await _applicationsCollection
          .where('hackathonId', isEqualTo: application.hackathonId)
          .where('userId', isEqualTo: application.userId)
          .get();
      if (existing.docs.isNotEmpty) {
        throw Exception('You have already applied for this hackathon');
      }

      final doc = _applicationsCollection.doc();
      final newApp = application.copyWith(id: doc.id);
      await doc.set(newApp.toFirestore());
      return newApp;
    } catch (e) {
      rethrow;
    }
  }

  /// Get applications by user
  Future<List<ApplicationModel>> getUserApplications(String userId) async {
    try {
      final snapshot = await _applicationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('appliedAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => ApplicationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== USER / TEAM VIEWS ====================

  /// Get all registered students
  Future<List<UserModel>> getAllStudents() async {
    try {
      final snapshot = await _usersCollection
          .where('role', isNotEqualTo: 'admin')
          .get();
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Fallback: fetch all and filter
      try {
        final snapshot = await _usersCollection.get();
        return snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .where((u) => u.role != 'admin')
            .toList();
      } catch (e2) {
        rethrow;
      }
    }
  }

  /// Get all teams
  Future<List<TeamModel>> getAllTeams() async {
    try {
      final snapshot = await _teamsCollection.get();
      return snapshot.docs
          .map((doc) => TeamModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get dashboard stats
  Future<Map<String, int>> getDashboardStats() async {
    try {
      final users = await _usersCollection.get();
      final teams = await _teamsCollection.get();
      final hackathons = await _hackathonsCollection.get();
      final applications = await _applicationsCollection.get();

      final studentCount =
          users.docs.where((d) => (d.data()['role'] ?? '') != 'admin').length;
      final pendingApps = applications.docs
          .where((d) => (d.data()['status'] ?? '') == 'pending')
          .length;

      return {
        'students': studentCount,
        'teams': teams.docs.length,
        'hackathons': hackathons.docs.length,
        'applications': applications.docs.length,
        'pendingApplications': pendingApps,
      };
    } catch (e) {
      rethrow;
    }
  }
}

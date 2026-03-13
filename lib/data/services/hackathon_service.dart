import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hackathon_model.dart';

/// Hackathon service for CodeClub
/// Handles all hackathon-related Firestore operations
class HackathonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _hackathonsCollection =>
      _firestore.collection('hackathons');

  // ==================== HACKATHON OPERATIONS ====================

  /// Get all hackathons
  Future<List<HackathonModel>> getAllHackathons() async {
    try {
      final snapshot = await _hackathonsCollection
          .orderBy('startDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => HackathonModel.fromFirestore(doc))
          .where((h) => h.isVisibleToStudents)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get upcoming hackathons
  Future<List<HackathonModel>> getUpcomingHackathons() async {
    try {
      final now = DateTime.now();
      final all = await getAllHackathons();
      return all
          .where((h) => h.startDate.isAfter(now))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get ongoing hackathons
  Future<List<HackathonModel>> getOngoingHackathons() async {
    try {
      final now = DateTime.now();
      final allHackathons = await getAllHackathons();
      
      return allHackathons
          .where((h) => h.startDate.isBefore(now) && h.endDate.isAfter(now))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get hackathon by ID
  Future<HackathonModel?> getHackathonById(String hackathonId) async {
    try {
      final doc = await _hackathonsCollection.doc(hackathonId).get();
      if (doc.exists) {
        return HackathonModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Stream of hackathons
  Stream<List<HackathonModel>> getHackathonsStream() {
    return _hackathonsCollection
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HackathonModel.fromFirestore(doc))
            .where((h) => h.isVisibleToStudents)
            .toList());
  }

  // ==================== REGISTRATION OPERATIONS ====================

  /// Register individual for hackathon
  Future<void> registerIndividual(String hackathonId, String userId) async {
    try {
      await _hackathonsCollection.doc(hackathonId).update({
        'registeredIndividualIds': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Register team for hackathon
  Future<void> registerTeam(String hackathonId, String teamId) async {
    try {
      await _hackathonsCollection.doc(hackathonId).update({
        'registeredTeamIds': FieldValue.arrayUnion([teamId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Unregister individual from hackathon
  Future<void> unregisterIndividual(String hackathonId, String userId) async {
    try {
      await _hackathonsCollection.doc(hackathonId).update({
        'registeredIndividualIds': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Unregister team from hackathon
  Future<void> unregisterTeam(String hackathonId, String teamId) async {
    try {
      await _hackathonsCollection.doc(hackathonId).update({
        'registeredTeamIds': FieldValue.arrayRemove([teamId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user is registered
  Future<bool> isUserRegistered(String hackathonId, String userId) async {
    try {
      final hackathon = await getHackathonById(hackathonId);
      if (hackathon == null) return false;
      return hackathon.registeredIndividualIds.contains(userId);
    } catch (e) {
      return false;
    }
  }

  /// Check if team is registered
  Future<bool> isTeamRegistered(String hackathonId, String teamId) async {
    try {
      final hackathon = await getHackathonById(hackathonId);
      if (hackathon == null) return false;
      return hackathon.registeredTeamIds.contains(teamId);
    } catch (e) {
      return false;
    }
  }

  /// Get hackathons user is registered for
  Future<List<HackathonModel>> getUserRegisteredHackathons(String userId) async {
    try {
      final snapshot = await _hackathonsCollection
          .where('registeredIndividualIds', arrayContains: userId)
          .get();

      return snapshot.docs
          .map((doc) => HackathonModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get hackathons team is registered for
  Future<List<HackathonModel>> getTeamRegisteredHackathons(String teamId) async {
    try {
      final snapshot = await _hackathonsCollection
          .where('registeredTeamIds', arrayContains: teamId)
          .get();

      return snapshot.docs
          .map((doc) => HackathonModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== ADMIN OPERATIONS (For future use) ====================

  /// Create hackathon (Admin only)
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

  /// Update hackathon (Admin only)
  Future<void> updateHackathon(HackathonModel hackathon) async {
    try {
      await _hackathonsCollection.doc(hackathon.id).update(hackathon.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  /// Delete hackathon (Admin only)
  Future<void> deleteHackathon(String hackathonId) async {
    try {
      await _hackathonsCollection.doc(hackathonId).delete();
    } catch (e) {
      rethrow;
    }
  }
}

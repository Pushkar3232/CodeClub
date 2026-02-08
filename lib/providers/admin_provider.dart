import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../data/models/application_model.dart';
import '../data/models/hackathon_model.dart';
import '../data/models/user_model.dart';
import '../data/models/team_model.dart';
import '../data/services/admin_service.dart';

/// Admin provider for managing admin state
class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  List<HackathonModel> _hackathons = [];
  List<ApplicationModel> _applications = [];
  List<UserModel> _students = [];
  List<TeamModel> _teams = [];
  Map<String, int> _dashboardStats = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<HackathonModel> get hackathons => _hackathons;
  List<ApplicationModel> get applications => _applications;
  List<UserModel> get students => _students;
  List<TeamModel> get teams => _teams;
  Map<String, int> get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<ApplicationModel> get pendingApplications =>
      _applications.where((a) => a.isPending).toList();

  // ==================== DASHBOARD ====================

  /// Load dashboard stats
  Future<void> loadDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      _dashboardStats = await _adminService.getDashboardStats();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    _safeNotifyListeners();
  }

  // ==================== HACKATHON CRUD ====================

  /// Load all hackathons for admin
  Future<void> loadHackathons() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      _hackathons = await _adminService.getAllHackathonsAdmin();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    _safeNotifyListeners();
  }

  /// Create hackathon
  Future<bool> createHackathon(HackathonModel hackathon) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final created = await _adminService.createHackathon(hackathon);
      _hackathons.insert(0, created);
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  /// Update hackathon
  Future<bool> updateHackathon(HackathonModel hackathon) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      await _adminService.updateHackathon(hackathon);
      final index = _hackathons.indexWhere((h) => h.id == hackathon.id);
      if (index != -1) {
        _hackathons[index] = hackathon;
      }
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  /// Delete hackathon
  Future<bool> deleteHackathon(String hackathonId) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      await _adminService.deleteHackathon(hackathonId);
      _hackathons.removeWhere((h) => h.id == hackathonId);
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  // ==================== APPLICATIONS ====================

  /// Load all applications
  Future<void> loadApplications() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      _applications = await _adminService.getAllApplications();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    _safeNotifyListeners();
  }

  /// Load applications for a specific hackathon
  Future<List<ApplicationModel>> loadApplicationsForHackathon(
      String hackathonId) async {
    try {
      return await _adminService.getApplicationsForHackathon(hackathonId);
    } catch (e) {
      _errorMessage = e.toString();
      _safeNotifyListeners();
      return [];
    }
  }

  /// Approve application
  Future<bool> approveApplication(
      String applicationId, String adminUid) async {
    try {
      await _adminService.approveApplication(applicationId, adminUid);
      final index = _applications.indexWhere((a) => a.id == applicationId);
      if (index != -1) {
        _applications[index] = _applications[index].copyWith(
          status: ApplicationStatus.approved,
          reviewedAt: DateTime.now(),
          reviewedBy: adminUid,
        );
      }
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _safeNotifyListeners();
      return false;
    }
  }

  /// Reject application
  Future<bool> rejectApplication(
      String applicationId, String adminUid, {String? remarks}) async {
    try {
      await _adminService.rejectApplication(applicationId, adminUid,
          remarks: remarks);
      final index = _applications.indexWhere((a) => a.id == applicationId);
      if (index != -1) {
        _applications[index] = _applications[index].copyWith(
          status: ApplicationStatus.rejected,
          reviewedAt: DateTime.now(),
          reviewedBy: adminUid,
          remarks: remarks,
        );
      }
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _safeNotifyListeners();
      return false;
    }
  }

  // ==================== USERS & TEAMS ====================

  /// Load all students
  Future<void> loadStudents() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      _students = await _adminService.getAllStudents();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    _safeNotifyListeners();
  }

  /// Load all teams
  Future<void> loadTeams() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      _teams = await _adminService.getAllTeams();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    _safeNotifyListeners();
  }

  // ==================== STUDENT-SIDE APPLICATIONS ====================

  /// Submit application (student use)
  Future<bool> submitApplication(ApplicationModel application) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      await _adminService.submitApplication(application);
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  /// Get user's applications
  Future<List<ApplicationModel>> getUserApplications(String userId) async {
    try {
      return await _adminService.getUserApplications(userId);
    } catch (e) {
      _errorMessage = e.toString();
      _safeNotifyListeners();
      return [];
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    _safeNotifyListeners();
  }

  /// Safe notify listeners
  void _safeNotifyListeners() {
    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../data/models/hackathon_model.dart';
import '../data/services/hackathon_service.dart';

/// Hackathon provider for managing hackathon state
class HackathonProvider extends ChangeNotifier {
  final HackathonService _hackathonService = HackathonService();

  List<HackathonModel> _hackathons = [];
  HackathonModel? _selectedHackathon;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<HackathonModel> get hackathons => _hackathons;
  HackathonModel? get selectedHackathon => _selectedHackathon;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Get upcoming hackathons
  List<HackathonModel> get upcomingHackathons =>
      _hackathons.where((h) => h.isUpcoming).toList();

  /// Get ongoing hackathons
  List<HackathonModel> get ongoingHackathons =>
      _hackathons.where((h) => h.isOngoing).toList();

  /// Get past hackathons
  List<HackathonModel> get pastHackathons =>
      _hackathons.where((h) => h.hasEnded).toList();

  /// Load all hackathons
  Future<void> loadHackathons() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      _hackathons = await _hackathonService.getAllHackathons();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    _safeNotifyListeners();
  }

  /// Register individual for hackathon
  Future<bool> registerIndividual(String hackathonId, String userId) async {
    try {
      _isLoading = true;
      _safeNotifyListeners();
      
      await _hackathonService.registerIndividual(hackathonId, userId);
      await loadHackathons(); // Refresh data
      
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

  /// Register team for hackathon
  Future<bool> registerTeam(String hackathonId, String teamId) async {
    try {
      _isLoading = true;
      _safeNotifyListeners();
      
      await _hackathonService.registerTeam(hackathonId, teamId);
      await loadHackathons(); // Refresh data
      
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

  /// Select a hackathon
  Future<void> selectHackathon(String hackathonId) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      _selectedHackathon = await _hackathonService.getHackathonById(hackathonId);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    _safeNotifyListeners();
  }

  /// Register as individual
  Future<bool> registerAsIndividual(String hackathonId, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      await _hackathonService.registerIndividual(hackathonId, userId);
      
      // Refresh selected hackathon
      if (_selectedHackathon?.id == hackathonId) {
        _selectedHackathon = await _hackathonService.getHackathonById(hackathonId);
      }
      
      // Refresh hackathons list
      await loadHackathons();
      
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

  /// Register as team
  Future<bool> registerAsTeam(String hackathonId, String teamId) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      await _hackathonService.registerTeam(hackathonId, teamId);
      
      // Refresh selected hackathon
      if (_selectedHackathon?.id == hackathonId) {
        _selectedHackathon = await _hackathonService.getHackathonById(hackathonId);
      }
      
      // Refresh hackathons list
      await loadHackathons();
      
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

  /// Check if user is registered
  bool isUserRegistered(String hackathonId, String userId) {
    final hackathon = _hackathons.firstWhere(
      (h) => h.id == hackathonId,
      orElse: () => _selectedHackathon ?? HackathonModel(
        id: '',
        title: '',
        description: '',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        registrationDeadline: DateTime.now(),
        venue: '',
        createdAt: DateTime.now(),
      ),
    );
    return hackathon.isUserRegistered(userId);
  }

  /// Check if team is registered
  bool isTeamRegistered(String hackathonId, String teamId) {
    final hackathon = _hackathons.firstWhere(
      (h) => h.id == hackathonId,
      orElse: () => _selectedHackathon ?? HackathonModel(
        id: '',
        title: '',
        description: '',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        registrationDeadline: DateTime.now(),
        venue: '',
        createdAt: DateTime.now(),
      ),
    );
    return hackathon.isTeamRegistered(teamId);
  }

  /// Clear selection
  void clearSelection() {
    _selectedHackathon = null;
    _safeNotifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    _safeNotifyListeners();
  }

  /// Safe notify listeners to avoid setState during build
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../data/models/team_model.dart';
import '../data/models/team_request_model.dart';
import '../data/models/user_model.dart';
import '../data/services/team_service.dart';
import '../data/services/user_service.dart';

/// Team provider for managing team state
class TeamProvider extends ChangeNotifier {
  final TeamService _teamService = TeamService();
  final UserService _userService = UserService();

  TeamModel? _currentTeam;
  List<UserModel> _teamMembers = [];
  List<TeamRequestModel> _incomingRequests = [];
  List<TeamRequestModel> _outgoingRequests = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Stream subscription management to prevent memory leaks
  StreamSubscription? _incomingRequestsSubscription;
  StreamSubscription? _outgoingRequestsSubscription;

  // Getters
  TeamModel? get currentTeam => _currentTeam;
  List<UserModel> get teamMembers => _teamMembers;
  List<TeamRequestModel> get incomingRequests => _incomingRequests;
  List<TeamRequestModel> get outgoingRequests => _outgoingRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasTeam => _currentTeam != null;

  /// Load current user's team
  Future<void> loadCurrentTeam(String? teamId) async {
    if (teamId == null) {
      _currentTeam = null;
      _teamMembers = [];
      _safeNotifyListeners();
      return;
    }

    _isLoading = true;
    _safeNotifyListeners();

    try {
      _currentTeam = await _teamService.getTeamById(teamId);
      if (_currentTeam != null) {
        _teamMembers = await _userService.getUsersByIds(_currentTeam!.memberIds);
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    _safeNotifyListeners();
  }

  /// Create a new team
  Future<bool> createTeam({
    required String name,
    required String leaderId,
    String? hackathonName,
    String? description,
    int maxSize = 4,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      _currentTeam = await _teamService.createTeam(
        name: name,
        leaderId: leaderId,
        hackathonName: hackathonName,
        description: description,
        maxSize: maxSize,
      );
      _teamMembers = await _userService.getUsersByIds(_currentTeam!.memberIds);
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

  /// Leave current team
  Future<bool> leaveTeam(String userId) async {
    if (_currentTeam == null) return false;

    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      await _teamService.removeMemberFromTeam(_currentTeam!.id, userId);
      _currentTeam = null;
      _teamMembers = [];
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

  /// Send team request
  Future<bool> sendTeamRequest({
    required String fromUserId,
    required String toUserId,
    String? message,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      await _teamService.sendTeamRequest(
        fromUserId: fromUserId,
        toUserId: toUserId,
        teamId: _currentTeam?.id,
        message: message,
      );
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

  /// Accept team request
  Future<bool> acceptRequest(TeamRequestModel request) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      await _teamService.acceptRequest(request);
      // Reload team if we joined one
      if (request.teamId != null) {
        await loadCurrentTeam(request.teamId);
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

  /// Reject team request
  Future<bool> rejectRequest(String requestId) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      await _teamService.rejectRequest(requestId);
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

  /// Listen to incoming requests
  void listenToIncomingRequests(String userId) {
    // Cancel existing subscription to prevent memory leak
    _incomingRequestsSubscription?.cancel();
    _incomingRequestsSubscription = _teamService.getIncomingRequests(userId).listen((requests) {
      _incomingRequests = requests;
      _safeNotifyListeners();
    });
  }

  /// Listen to outgoing requests
  void listenToOutgoingRequests(String userId) {
    // Cancel existing subscription to prevent memory leak
    _outgoingRequestsSubscription?.cancel();
    _outgoingRequestsSubscription = _teamService.getOutgoingRequests(userId).listen((requests) {
      _outgoingRequests = requests;
      _safeNotifyListeners();
    });
  }

  @override
  void dispose() {
    _incomingRequestsSubscription?.cancel();
    _outgoingRequestsSubscription?.cancel();
    super.dispose();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    _safeNotifyListeners();
  }

  /// Clear team data
  void clearTeamData() {
    _currentTeam = null;
    _teamMembers = [];
    _incomingRequests = [];
    _outgoingRequests = [];
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

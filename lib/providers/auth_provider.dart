import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';
import '../data/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart' hide FirebaseAuthException;

/// Authentication state provider
enum AuthState { initial, authenticated, unauthenticated, loading }

/// Auth provider for managing authentication state
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  AuthState _authState = AuthState.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  AuthState get authState => _authState;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authState == AuthState.authenticated;
  bool get isProfileComplete => _currentUser?.isProfileComplete ?? false;
  String? get currentUserId => _authService.currentUserId;

  AuthProvider() {
    _init();
  }

  /// Initialize auth state
  Future<void> _init() async {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        await _loadUserProfile();
        _authState = AuthState.authenticated;
      } else {
        _currentUser = null;
        _authState = AuthState.unauthenticated;
      }
      notifyListeners();
    });
  }

  /// Load current user profile
  Future<void> _loadUserProfile() async {
    try {
      _currentUser = await _authService.getCurrentUserProfile();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  /// Refresh user profile
  Future<void> refreshUserProfile() async {
    await _loadUserProfile();
    notifyListeners();
  }

  /// Sign up
  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signUp(email: email, password: password);
      await _loadUserProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.userMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signIn(email: email, password: password);
      await _loadUserProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.userMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
      _authState = AuthState.unauthenticated;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.userMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile(UserModel updatedUser) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _userService.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../data/services/admin_service.dart';
import '../admin/screens/admin_dashboard_screen.dart';
import '../admin/screens/admin_hackathon_create_screen.dart';
import '../admin/screens/admin_hackathon_detail_screen.dart';
import '../admin/screens/admin_hackathon_edit_screen.dart';
import '../admin/screens/admin_hackathon_list_screen.dart';
import '../admin/screens/admin_login_screen.dart';
import '../../data/models/hackathon_model.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/chat/create_group_screen.dart';
import '../screens/hackathon/hackathon_list_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/members/find_members_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/profile_setup_screen.dart';

/// App router configuration
class AppRouter {
  final AuthProvider authProvider;
  final AdminService _adminService = AdminService();

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    refreshListenable: _AuthStateNotifier(authProvider),
    initialLocation: '/login',
    redirect: (context, state) async {
      final isLoggedIn = authProvider.authState == AuthState.authenticated;
      final isAdminPath = state.matchedLocation.startsWith('/admin');
      final isAdminLogin = state.matchedLocation == '/admin/login';
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password' ||
          isAdminLogin;

      // If still initializing, don't redirect yet
      if (authProvider.authState == AuthState.initial) {
        return null;
      }

      if (isAdminPath) {
        if (isAdminLogin) {
          if (!isLoggedIn) {
            return null;
          }
          final isAdmin = await _adminService.isCurrentUserAdmin();
          return isAdmin ? '/admin/dashboard' : null;
        }

        if (!isLoggedIn) {
          return '/admin/login';
        }

        final isAdmin = await _adminService.isCurrentUserAdmin();
        if (!isAdmin) {
          return '/admin/login';
        }
        return null;
      }

      // If not logged in and not on auth page, redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // If logged in and on auth page, redirect to home
      if (isLoggedIn && isLoggingIn) {
        // Check if profile is complete
        final user = authProvider.currentUser;
        if (user != null && !user.isProfileComplete) {
          return '/profile-setup';
        }
        return '/home';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      // Main routes
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      // Profile routes
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      // Members routes
      GoRoute(
        path: '/find-members',
        name: 'find-members',
        builder: (context, state) => const FindMembersScreen(),
      ),
      // Chat routes
      GoRoute(
        path: '/chats',
        name: 'chats',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:chatId',
        name: 'chat',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          final title = state.uri.queryParameters['title'] ?? 'Chat';
          final isGroupChat = state.uri.queryParameters['isGroup'] == 'true';
          return ChatScreen(
            chatId: chatId,
            title: title,
            isGroupChat: isGroupChat,
          );
        },
      ),
      // Create group route
      GoRoute(
        path: '/create-group',
        name: 'create-group',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      // Hackathon routes
      GoRoute(
        path: '/hackathons',
        name: 'hackathons',
        builder: (context, state) => const HackathonListScreen(),
      ),
      // Admin routes
      GoRoute(
        path: '/admin/login',
        name: 'admin-login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/hackathons',
        name: 'admin-hackathon-list',
        builder: (context, state) => const AdminHackathonListScreen(),
      ),
      GoRoute(
        path: '/admin/hackathons/create',
        name: 'admin-hackathon-create',
        builder: (context, state) => const AdminHackathonCreateScreen(),
      ),
      GoRoute(
        path: '/admin/hackathons/edit',
        name: 'admin-hackathon-edit',
        builder: (context, state) {
          final hackathon = state.extra as HackathonModel;
          return AdminHackathonEditScreen(hackathon: hackathon);
        },
      ),
      GoRoute(
        path: '/admin/hackathons/detail',
        name: 'admin-hackathon-detail',
        builder: (context, state) {
          final hackathon = state.extra as HackathonModel;
          return AdminHackathonDetailScreen(hackathon: hackathon);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Custom notifier for auth state changes to prevent excessive router rebuilds
class _AuthStateNotifier extends ChangeNotifier {
  final AuthProvider _authProvider;
  AuthState? _lastAuthState;

  _AuthStateNotifier(this._authProvider) {
    _lastAuthState = _authProvider.authState;
    _authProvider.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    if (_authProvider.authState != _lastAuthState) {
      _lastAuthState = _authProvider.authState;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}

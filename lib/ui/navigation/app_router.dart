import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/hackathon/hackathon_list_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/members/find_members_screen.dart';
import '../screens/members/team_requests_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/profile_setup_screen.dart';
import '../screens/team/create_team_screen.dart';
import '../screens/team/join_team_screen.dart';
import '../screens/team/team_dashboard_screen.dart';

/// App router configuration
class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    refreshListenable: authProvider,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authProvider.authState == AuthState.authenticated;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password';

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
      // Team routes
      GoRoute(
        path: '/create-team',
        name: 'create-team',
        builder: (context, state) => const CreateTeamScreen(),
      ),
      GoRoute(
        path: '/team-dashboard',
        name: 'team-dashboard',
        builder: (context, state) => const TeamDashboardScreen(),
      ),
      GoRoute(
        path: '/join-team',
        name: 'join-team',
        builder: (context, state) => const JoinTeamScreen(),
      ),
      GoRoute(
        path: '/team-requests',
        name: 'team-requests',
        builder: (context, state) => const TeamRequestsScreen(),
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
          final isGroupChat =
              state.uri.queryParameters['isGroup'] == 'true';
          return ChatScreen(
            chatId: chatId,
            title: title,
            isGroupChat: isGroupChat,
          );
        },
      ),
      // Hackathon routes
      GoRoute(
        path: '/hackathons',
        name: 'hackathons',
        builder: (context, state) => const HackathonListScreen(),
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

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/hackathon_provider.dart';
import 'providers/team_provider.dart';
import 'providers/theme_provider.dart';
import 'ui/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
    print('Running without Firebase - some features may not work');
    // Continue without Firebase for now - you can still test the UI
  }

  // Set preferred orientations (skip on web)
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    print('Orientation setting skipped (likely web platform): $e');
  }

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(CodeClubApp(prefs: prefs));
}

class CodeClubApp extends StatelessWidget {
  final SharedPreferences prefs;

  const CodeClubApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Auth provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Admin provider
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        // Team provider
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        // Chat provider
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        // Hackathon provider
        ChangeNotifierProvider(create: (_) => HackathonProvider()),
      ],
      child: const _AppContent(),
    );
  }
}

class _AppContent extends StatefulWidget {
  const _AppContent();

  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> {
  late final AuthProvider _authProvider;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    // We'll initialize in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize once - create AppRouter only once to prevent rebuilds
    if (!_isInitialized) {
      _authProvider = context.read<AuthProvider>();
      _appRouter = AppRouter(_authProvider);
      _isInitialized = true;
    }
  }

  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        try {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _appRouter.router,
          );
        } catch (e) {
          // Fallback UI in case of routing issues
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'App Initialization Error',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Error: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Reload the app
                        main();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

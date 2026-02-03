import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
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
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        // Auth provider
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        // Team provider
        ChangeNotifierProvider(
          create: (_) => TeamProvider(),
        ),
        // Chat provider
        ChangeNotifierProvider(
          create: (_) => ChatProvider(),
        ),
        // Hackathon provider
        ChangeNotifierProvider(
          create: (_) => HackathonProvider(),
        ),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, _) {
          try {
            final appRouter = AppRouter(authProvider);
            
            return MaterialApp.router(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              routerConfig: appRouter.router,
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
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'App Initialization Error',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Error: $e'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Reload the app
                          main();
                        },
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}


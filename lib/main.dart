/// ============================================================
/// ThirdSpace — "Social Gravity" Map (Flutter MVP)
/// ============================================================
/// Architecture: Provider-based state management with clean
/// separation of concerns. Firebase Auth gates the app.
///
/// Data Flow:
///   Firebase Auth → Provider (AppState) → UI Screens
///   Location: Geolocator → AppState → MapScreen
/// ============================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'core/app_state.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'screens/username_setup_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Lock to portrait for the mobile-first "Social Gravity" experience
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style to match our dark theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: TSColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const ThirdSpaceApp());
}

class ThirdSpaceApp extends StatelessWidget {
  const ThirdSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'ThirdSpace',
        debugShowCheckedModeBanner: false,
        theme: ThirdSpaceTheme.darkTheme,
        home: const _AuthGate(),
      ),
    );
  }
}

/// Routes to LoginScreen or AppShell based on auth state
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.isAuthenticated) {
      final profile = state.userProfile;
      if (profile == null) {
        // Profile still loading from Firestore
        return const Scaffold(
          backgroundColor: TSColors.surface,
          body: Center(child: CircularProgressIndicator(color: TSColors.primary)),
        );
      }
      if (profile.username.isEmpty) {
        return const UsernameSetupScreen();
      }
      return const AppShell();
    } else {
      return const LoginScreen();
    }
  }
}

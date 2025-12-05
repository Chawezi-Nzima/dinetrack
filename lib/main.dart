import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dinetrack/flavors//operator/screens/home_operator.dart';

import 'core/services/supabase_service.dart';
import 'core/utils/platform_detector.dart';
import 'login_page.dart';
import 'landingPage.dart';
import 'core/routing/role_router.dart';
// Add these imports
import 'screens/admin_registration.dart';
import 'screens/email_verification_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Detect environment
  const env = String.fromEnvironment(
    'FLUTTER_ENV',
    defaultValue: 'production',
  );

  // Load correct env file
  await dotenv.load(fileName: "assets/env/.env.$env");

  // Initialize Supabase using ENV values
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize DineTrack services
  await SupabaseService().postInit();

  runApp(const DineTrackApp());
}

class DineTrackApp extends StatelessWidget {
  const DineTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DineTrack',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      home: const AuthGate(),

      routes: {
        '/operator-home': (context) => const OperatorHomeScreen(),
      },

      debugShowCheckedModeBanner: false,
    );
  }
}

/// Platform aware wrapper widget
class PlatformAwareWrapper extends StatelessWidget {
  final Widget mobileApp;
  final Widget webInterface;
  final Widget loadingScreen;

  const PlatformAwareWrapper({
    super.key,
    required this.mobileApp,
    required this.webInterface,
    required this.loadingScreen,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: Future.delayed(const Duration(milliseconds: 500), () => true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingScreen;
        }

        // Use the platform description to determine if we're on mobile
        final platform = PlatformDetector.platformDescription.toLowerCase();
        final isMobile = platform.contains('android') ||
            platform.contains('ios') ||
            platform.contains('mobile');

        if (isMobile || PlatformDetector.isMobileWeb) {
          return mobileApp;
        } else {
          return webInterface;
        }
      },
    );
  }
}

/// AUTH GATE — checks Supabase session changes
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformAwareWrapper(
      mobileApp: const MobileAppGateway(),
      webInterface: const LandingPage(),
      loadingScreen: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                'Loading DineTrack...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'Platform: ${PlatformDetector.platformDescription}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mobile App Gateway - for mobile devices and mobile browsers
class MobileAppGateway extends StatelessWidget {
  const MobileAppGateway({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Initializing app...',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final authState = snapshot.data;
        final session = authState?.session;

        if (session == null) {
          return const _AuthFlowNavigator();
        }

        return RoleBasedRouter(userId: session.user.id);
      },
    );
  }
}

/// Handles authentication flow navigation
class _AuthFlowNavigator extends StatefulWidget {
  const _AuthFlowNavigator({super.key});

  @override
  State<_AuthFlowNavigator> createState() => _AuthFlowNavigatorState();
}

class _AuthFlowNavigatorState extends State<_AuthFlowNavigator> {
  @override
  Widget build(BuildContext context) {
    return const AdminRegistrationPage();
  }
}
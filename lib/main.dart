import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/supabase_service.dart';
import 'login_page.dart';
import 'core/routing/role_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await SupabaseService().initialize();

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
      debugShowCheckedModeBanner: false,
    );
  }
}

/// AUTH GATE — checks if user is logged in using Supabase
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final authState = snapshot.data;
        final session = authState?.session;

        if (session == null) {
          return const LoginPage(); // User not signed in
        }

        return RoleBasedRouter(userId: session.user.id);
      },
    );
  }
}
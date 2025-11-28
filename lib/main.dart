import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

// Import your real UI screens
import 'login_page.dart';
import 'flavors/customer/screens/home_customer.dart';
import 'flavors/operator/screens/home_operator.dart';
import 'flavors/kitchen/screens/home_kitchen.dart';
import 'flavors/supervisor/screens/home_supervisor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
  // Firestore emulator
  FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);

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

/// AUTH GATE — checks if user is logged in
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final user = snap.data;
        if (user == null) {
          return const LoginPage(); // <--- Your redesigned login page
        }

        return RoleRouter(user: user);
      },
    );
  }
}

/// ROLE ROUTER — loads the correct UI for Customer, Operator, Kitchen, Supervisor
class RoleRouter extends StatefulWidget {
  final User user;
  const RoleRouter({required this.user, super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  String? _role;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final token = await widget.user.getIdTokenResult(true);

      if (token.claims != null && token.claims!['role'] != null) {
        _role = token.claims!['role'];
      } else {
        // fallback to Firestore users collection
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          _role = doc.data()!['role'];
        }
      }
    } catch (e) {
      _error = 'Could not load user role: $e';
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    switch (_role?.toLowerCase()) {
      case 'customer':
        return CustomerHomeScreen();
      case 'operator':
        return OperatorHomeScreen();
      case 'kitchen':
        return KitchenHomeScreen();
      case 'supervisor':
        return SupervisorHomeScreen();
      default:
        return Scaffold(
          body: Center(
            child: Text('Unknown role: $_role'),
          ),
        );
    }
  }
}

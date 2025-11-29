import 'package:flutter/material.dart';
//import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';

class OperatorHomeScreen extends StatelessWidget {
  const OperatorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operator Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => SupabaseService().signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant, size: 64, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Welcome Operator!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Restaurant Management Console'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => SupabaseService().signOut(),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
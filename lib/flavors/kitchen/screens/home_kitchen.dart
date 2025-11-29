import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';

class KitchenHomeScreen extends StatelessWidget {
  const KitchenHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Dashboard'),
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
            const Icon(Icons.kitchen, size: 64, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              'Welcome Kitchen Staff!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Order Management Panel'),
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
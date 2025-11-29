// lib/flavors/customer/screens/group_order_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/services/supabase_service.dart';

class GroupOrderScreen extends StatefulWidget {
  final String establishmentId;
  const GroupOrderScreen({super.key, required this.establishmentId});

  @override
  State<GroupOrderScreen> createState() => _GroupOrderScreenState();
}

class _GroupOrderScreenState extends State<GroupOrderScreen> {
  final SupabaseService _svc = SupabaseService();
  String? _sessionId;
  final Map<String, int> _localCart = {};
  bool _creating = false;

  Future<void> _createSession() async {
    setState(() => _creating = true);
    try {
      // Minimal local session ID. For production, create server-side row (group_sessions)
      final gen = DateTime.now().millisecondsSinceEpoch.toString();
      setState(() => _sessionId = gen);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group session created')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      setState(() => _creating = false);
    }
  }

  void _joinSession(String id) {
    setState(() => _sessionId = id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined session')));
  }

  void _addItem(String itemId) {
    setState(() => _localCart[itemId] = (_localCart[itemId] ?? 0) + 1);
  }

  void _leaveSession() {
    setState(() { _sessionId = null; _localCart.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group Order')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (_sessionId == null)
              Column(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.group_add),
                    label: const Text('Start Group Order'),
                    onPressed: _creating ? null : _createSession,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Enter session ID to join'),
                    onSubmitted: (v) { if(v.isNotEmpty) _joinSession(v); },
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Session: $_sessionId', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Leave Session'),
                    onPressed: _leaveSession,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  ),
                  const SizedBox(height: 12),
                  // Minimal local UI: participants and cart summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text('Participants', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('You (demo)'),
                          const SizedBox(height: 12),
                          const Text('Items (local):'),
                          ..._localCart.entries.map((e) => ListTile(title: Text('${e.key} x ${e.value}'))),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () { /* TODO: submit group order to server */ },
                            child: const Text('Submit Group Order'),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              )
          ],
        ),
      ),
    );
  }
}

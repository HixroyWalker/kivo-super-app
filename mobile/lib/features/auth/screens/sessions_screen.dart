import 'package:flutter/material.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final List<Map<String, dynamic>> _sessions = [
    {
      'id': 's1',
      'device': 'iPhone 15 Pro (This Device)',
      'location': 'Kingston, Jamaica',
      'lastActive': 'Active Now',
      'isCurrent': true,
    },
    {
      'id': 's2',
      'device': 'Samsung Galaxy S23',
      'location': 'Montego Bay, Jamaica',
      'lastActive': '2 hours ago',
      'isCurrent': false,
    },
    {
      'id': 's3',
      'device': 'Chrome on macOS',
      'location': 'Spanish Town, Jamaica',
      'lastActive': 'Yesterday',
      'isCurrent': false,
    },
  ];

  void _revokeSession(String id, String device) {
    setState(() {
      _sessions.removeWhere((s) => s['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Revoked session for $device')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Devices & Sessions'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          final isCurrent = session['isCurrent'] as bool;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                isCurrent ? Icons.phone_iphone : Icons.devices,
                color: isCurrent ? Colors.green : Colors.grey,
                size: 32,
              ),
              title: Text(session['device'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${session['location']} • ${session['lastActive']}'),
              trailing: isCurrent
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                      child: const Text('This Phone', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                    )
                  : IconButton(
                      icon: const Icon(Icons.output, color: Colors.red),
                      tooltip: 'Revoke Access',
                      onPressed: () => _revokeSession(session['id'], session['device']),
                    ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // In a real implementation, you would fetch these from Firestore 
    // or a local SQLite database that stores push notification payloads.
    final List<Map<String, dynamic>> mockNotifications = [
      {'title': 'Money Received!', 'body': 'You received \$500 JMD from John Doe', 'time': '2 mins ago', 'icon': Icons.arrow_downward, 'color': Colors.green},
      {'title': 'Ad Reward', 'body': 'You earned \$5 JMD for watching an ad.', 'time': '1 hour ago', 'icon': Icons.monetization_on, 'color': Colors.amber},
      {'title': 'New Message', 'body': 'Sarah sent you a secure message.', 'time': 'Yesterday', 'icon': Icons.message, 'color': Colors.blue},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: mockNotifications.isEmpty
          ? const Center(child: Text('No new notifications'))
          : ListView.separated(
              itemCount: mockNotifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notif = mockNotifications[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: notif['color'].withOpacity(0.2),
                    child: Icon(notif['icon'], color: notif['color']),
                  ),
                  title: Text(notif['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(notif['body']),
                  trailing: Text(notif['time'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  onTap: () {
                    // Navigate to relevant screen based on payload
                  },
                );
              },
            ),
    );
  }
}

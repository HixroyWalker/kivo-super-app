import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class MessagingScreen extends StatelessWidget {
  const MessagingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        itemCount: 15,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text('Merchant $index', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Yes, the item is still available!'),
            trailing: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('2:30 PM', style: TextStyle(color: Colors.grey, fontSize: 12)),
                SizedBox(height: 4),
                CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Text('1', style: TextStyle(color: Colors.white, fontSize: 12))),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(merchantName: 'Merchant $index'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

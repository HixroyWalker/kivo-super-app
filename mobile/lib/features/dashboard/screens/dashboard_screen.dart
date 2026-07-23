import 'package:flutter/material.dart';
import '../../ads/screens/ads_screen.dart';
import '../../notifications/screens/notifications_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kivo Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            color: Colors.green,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
                SizedBox(height: 8),
                Text('JMD \$15,000.00', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          // Service Grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildGridTile(context, Icons.account_balance_wallet, 'P2P Wallet', Colors.blue, '/wallet'),
                _buildGridTile(context, Icons.storefront, 'Marketplace', Colors.orange, '/marketplace'),
                _buildGridTile(context, Icons.message, 'Messaging', Colors.purple, '/messaging'),
                _buildGridTile(context, Icons.analytics, 'Accounting', Colors.teal, '/accounting'),
                _buildGridTile(context, Icons.monetization_on, 'Watch & Earn', Colors.amber, '/ads'),
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Trigger Lynk API Top-Up
        },
        label: const Text('Top Up via Lynk'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  Widget _buildGridTile(BuildContext context, IconData icon, String title, Color color, String route) {
    return InkWell(
      onTap: () {
        if (route == '/ads') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AdsScreen()));
        } else {
            Navigator.pushNamed(context, route);
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

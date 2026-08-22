import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/vendor_provider.dart';

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vendor Portal'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
              Tab(icon: Icon(Icons.inventory), text: 'Products'),
              Tab(icon: Icon(Icons.local_shipping), text: 'Orders'),
              Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OverviewTab(),
            Center(child: Text('Products Manager Coming Soon')),
            Center(child: Text('Order Management Coming Soon')),
            Center(child: Text('Analytics Coming Soon')),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<VendorProvider>(
      builder: (context, vendor, _) {
        if (vendor.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final config = vendor.storefrontConfig;
        if (config == null) {
          return const Center(child: Text('Failed to load store data.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config['businessName'] ?? 'Your Store',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text('Store ID: ${config['merchantId']}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Earnings',
                    value: 'JMD \$${vendor.totalEarnings.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet,
                    color: const Color(0xFF00C853),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Pending Payout',
                    value: 'JMD \$${vendor.pendingPayout.toStringAsFixed(2)}',
                    icon: Icons.hourglass_empty,
                    color: const Color(0xFFFFD700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to Storefront Editor
              },
              icon: const Icon(Icons.store),
              label: const Text('Edit Storefront Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

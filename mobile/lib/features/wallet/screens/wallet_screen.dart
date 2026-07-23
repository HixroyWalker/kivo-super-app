import 'package:flutter/material.dart';
import '../widgets/transfer_modal.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  void _showTransferModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const TransferModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P2P Wallet & Social'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.green.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showTransferModal(context),
                  icon: const Icon(Icons.send),
                  label: const Text('Send / Pay'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan QR'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: 20,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: [
                        const TextSpan(text: 'UserA ', style: TextStyle(fontWeight: FontWeight.bold)),
                        const TextSpan(text: 'paid '),
                        const TextSpan(text: 'UserB', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  subtitle: const Text('Thanks for dinner! 🍔🔥\n2 hours ago'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.favorite_border, size: 20),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

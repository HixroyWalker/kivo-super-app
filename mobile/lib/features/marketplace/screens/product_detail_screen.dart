import 'package:flutter/material.dart';
import '../../wallet/widgets/transfer_modal.dart';

class ProductDetailScreen extends StatelessWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  void _showCheckout(BuildContext context) {
    // In a real app, this would pass the product amount to the transfer modal
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
      appBar: AppBar(title: const Text('Product Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 250,
              color: Colors.grey.shade300,
              child: const Center(child: Icon(Icons.image, size: 80)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Awesome Product $productId', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('JMD \$1,500', style: TextStyle(fontSize: 20, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text(
                    'This is a highly detailed description of the product. It explains all the features and benefits. Buying this directly from the marketplace supports local Jamaican businesses.',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _showCheckout(context),
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: const Text('Buy Now with Kivo Balance'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Mock navigation to chat
                      Navigator.pushNamed(context, '/messaging');
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Message Seller'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

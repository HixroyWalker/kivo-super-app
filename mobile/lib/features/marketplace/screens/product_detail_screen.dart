import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/dark_theme.dart';
import '../../../core/services/marketplace_provider.dart';
import '../../../core/services/wallet_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  void _showCheckoutDialog(BuildContext context) {
    final marketplace = context.read<MarketplaceProvider>();
    final wallet = context.read<WalletProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KivoDarkTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Purchase', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: ${product.name}', style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Text('Merchant: ${product.sellerName}', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Text('Amount: JMD \$${product.price.toStringAsFixed(2)}', style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Text('Wallet Balance: ${wallet.formattedBalance}', style: const TextStyle(color: KivoDarkTheme.accentCyan, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: KivoDarkTheme.textSecondary))),
          ElevatedButton(
            onPressed: () {
              if (wallet.jmdBalance >= product.price) {
                wallet.sendMoney(product.sellerName, product.price, 'Purchase: ${product.name}');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: KivoDarkTheme.surfaceElevated,
                    content: Text(
                      'Payment of JMD \$${product.price.toStringAsFixed(2)} completed! Order is being processed.',
                      style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Insufficient wallet balance. Please top up first.'),
                  ),
                );
              }
            },
            child: const Text('Confirm & Pay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marketplace = context.watch<MarketplaceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Header
            Hero(
              tag: product.id,
              child: SizedBox(
                height: 280,
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: KivoDarkTheme.surface, child: const Center(child: CircularProgressIndicator())),
                  errorWidget: (_, __, ___) => Container(color: KivoDarkTheme.surface, child: const Icon(Icons.broken_image, size: 60)),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: KivoDarkTheme.primaryEmerald.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.category,
                      style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: KivoDarkTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: KivoDarkTheme.accentAmber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${product.rating} (${product.reviewsCount} reviews)',
                        style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.verified, color: KivoDarkTheme.accentCyan, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        product.sellerName,
                        style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'JMD \$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: KivoDarkTheme.primaryEmerald,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'About This Item',
                    style: TextStyle(
                      color: KivoDarkTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            marketplace.addToCart(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart!'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Add to Cart'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showCheckoutDialog(context),
                          icon: const Icon(Icons.flash_on, size: 18),
                          label: const Text('Buy Now'),
                        ),
                      ),
                    ],
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

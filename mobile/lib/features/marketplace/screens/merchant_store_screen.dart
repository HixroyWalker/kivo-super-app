import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/dark_theme.dart';
import '../../../core/services/marketplace_provider.dart';
import 'product_detail_screen.dart';
import '../../messaging/screens/chat_detail_screen.dart';

class MerchantStoreScreen extends StatelessWidget {
  final MerchantProfile merchant;

  const MerchantStoreScreen({super.key, required this.merchant});

  @override
  Widget build(BuildContext context) {
    final marketplace = context.watch<MarketplaceProvider>();
    final merchantProducts = marketplace.getProductsByMerchant(merchant.id);

    return Scaffold(
      backgroundColor: KivoDarkTheme.background,
      body: CustomScrollView(
        slivers: [
          // 1. Merchant Hero Banner & App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: KivoDarkTheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: merchant.bannerUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: KivoDarkTheme.surface),
                    errorWidget: (_, __, ___) => Container(color: KivoDarkTheme.surfaceElevated),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Merchant Profile Info Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: KivoDarkTheme.primaryEmerald, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundImage: CachedNetworkImageProvider(merchant.avatarUrl),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    merchant.name,
                                    style: const TextStyle(
                                      color: KivoDarkTheme.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.verified, color: KivoDarkTheme.primaryEmerald, size: 18),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${merchant.handle} • ${merchant.town}, ${merchant.parish} 🇯🇲',
                              style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${merchant.rating} (${merchant.reviewsCount} reviews)',
                                  style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Text(
                    merchant.description,
                    style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 14),

                  // Delivery Restriction Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: KivoDarkTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KivoDarkTheme.primaryEmerald.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          merchant.deliveryType == 'pickup_only' ? Icons.store : Icons.local_shipping,
                          color: KivoDarkTheme.primaryEmerald,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                merchant.deliveryType == 'all_island'
                                    ? 'All-Island Delivery (14 Parishes)'
                                    : merchant.deliveryType == 'pickup_only'
                                        ? 'In-Store Pickup Only'
                                        : 'Delivers to: ${merchant.allowedParishes.join(", ")}',
                                style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              Text(
                                merchant.deliveryType == 'pickup_only'
                                    ? 'Pickup location: ${merchant.town}, ${merchant.parish}'
                                    : 'Delivery from JMD \$${merchant.standardDeliveryFee.toStringAsFixed(0)}',
                                style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons (Message Merchant)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(
                                  contactName: merchant.name,
                                  isOnline: true,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 16, color: KivoDarkTheme.accentCyan),
                          label: const Text('Message Merchant', style: TextStyle(color: KivoDarkTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: KivoDarkTheme.accentCyan),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Products (${merchantProducts.length})',
                        style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: KivoDarkTheme.primaryEmerald.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Direct Storefront', style: TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // 3. Products Grid exclusively for this merchant
          if (merchantProducts.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text('No products currently listed for this merchant.', style: TextStyle(color: KivoDarkTheme.textSecondary)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = merchantProducts[index];
                    return _buildProductCard(context, product, marketplace);
                  },
                  childCount: merchantProducts.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, MarketplaceProvider marketplace) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: KivoDarkTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KivoDarkTheme.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: KivoDarkTheme.surfaceElevated),
                      errorWidget: (_, __, ___) => Container(color: KivoDarkTheme.surfaceElevated, child: const Icon(Icons.image)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KivoDarkTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'JMD \$${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: KivoDarkTheme.primaryEmerald,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.add_shopping_cart, color: KivoDarkTheme.primaryEmerald, size: 18),
                        onPressed: () {
                          marketplace.addToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 1),
                              content: Text('Added ${product.name} to cart!'),
                            ),
                          );
                        },
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

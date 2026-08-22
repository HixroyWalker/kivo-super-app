import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/dark_theme.dart';
import '../../../core/services/marketplace_provider.dart';
import '../../../core/services/wallet_provider.dart';
import 'product_detail_screen.dart';
import 'merchant_store_screen.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  void _showCartSheet(BuildContext context) {
    final marketplace = context.read<MarketplaceProvider>();
    final wallet = context.read<WalletProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final items = marketplace.cartItems;
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: KivoDarkTheme.surfaceElevated,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Cart (${marketplace.cartCount} items)',
                      style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (items.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          marketplace.clearCart();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear All', style: TextStyle(color: KivoDarkTheme.accentRose, fontSize: 13)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('Your cart is empty', style: TextStyle(color: KivoDarkTheme.textSecondary)),
                    ),
                  )
                else ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(color: KivoDarkTheme.surfaceBorder),
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: item.product.imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                                  Text('Sold by: ${item.product.sellerName}', style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
                                  Text('JMD \$${item.product.price.toStringAsFixed(2)}', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: KivoDarkTheme.textSecondary),
                                  onPressed: () {
                                    marketplace.removeFromCart(item.product.id);
                                    setSheetState(() {});
                                  },
                                ),
                                Text('${item.quantity}', style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 20, color: KivoDarkTheme.primaryEmerald),
                                  onPressed: () {
                                    marketplace.addToCart(item.product);
                                    setSheetState(() {});
                                  },
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 14)),
                      Text(
                        'JMD \$${marketplace.cartSubtotal.toStringAsFixed(2)}',
                        style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (items.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(product: items.first.product),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KivoDarkTheme.primaryEmerald,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Proceed to Delivery & Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marketplace = context.watch<MarketplaceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kivo Market 🇯🇲'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: marketplace.cartCount > 0,
              label: Text('${marketplace.cartCount}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            onPressed: () => _showCartSheet(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: marketplace.setSearchQuery,
              style: const TextStyle(color: KivoDarkTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search coffee, baked goods, artisan crafts...',
                prefixIcon: Icon(Icons.search, color: KivoDarkTheme.textSecondary),
              ),
            ),
          ),

          // 2. Featured Stores Carousel (Single Merchant Store Access)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Jamaican Stores & Artisans',
                  style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${marketplace.merchants.length} Verified',
                  style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 94,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: marketplace.merchants.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, idx) {
                final m = marketplace.merchants[idx];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MerchantStoreScreen(merchant: m)),
                    );
                  },
                  child: Container(
                    width: 130,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: KivoDarkTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: KivoDarkTheme.surfaceBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: CachedNetworkImageProvider(m.avatarUrl),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          m.parish,
                          style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // 3. Category Filter Pills
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: marketplace.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = marketplace.categories[i];
                final isSelected = cat == marketplace.selectedCategory;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) => marketplace.setCategory(cat),
                  selectedColor: KivoDarkTheme.primaryEmerald.withOpacity(0.2),
                  backgroundColor: KivoDarkTheme.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isSelected ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.surfaceBorder,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // 4. Product Grid
          Expanded(
            child: marketplace.filteredProducts.isEmpty
                ? const Center(
                    child: Text('No products found matching your search.', style: TextStyle(color: KivoDarkTheme.textSecondary)),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.70,
                    ),
                    itemCount: marketplace.filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = marketplace.filteredProducts[index];
                      final merchant = marketplace.getMerchant(p.merchantId);

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(product: p),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
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
                                        imageUrl: p.imageUrl,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(color: KivoDarkTheme.surfaceElevated),
                                        errorWidget: (_, __, ___) => const Center(child: Icon(Icons.image, size: 40)),
                                      ),
                                    ),
                                    if (p.isFeatured)
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: KivoDarkTheme.primaryEmerald,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text('FEATURED', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
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
                                      p.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    const SizedBox(height: 2),

                                    // Merchant Name with Store Link
                                    GestureDetector(
                                      onTap: () {
                                        if (merchant != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => MerchantStoreScreen(merchant: merchant)),
                                          );
                                        }
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(Icons.storefront, size: 12, color: KivoDarkTheme.primaryEmerald),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              p.sellerName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: KivoDarkTheme.primaryEmerald,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'JMD \$${p.price.toStringAsFixed(0)}',
                                          style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 14),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            marketplace.addToCart(p);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('${p.name} added to cart!'),
                                                duration: const Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: KivoDarkTheme.primaryEmerald.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.add_shopping_cart, size: 16, color: KivoDarkTheme.primaryEmerald),
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
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

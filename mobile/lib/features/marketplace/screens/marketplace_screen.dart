import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/dark_theme.dart';
import '../../../core/services/marketplace_provider.dart';
import '../../../core/services/wallet_provider.dart';
import '../../merchant/screens/pos_cashier_screen.dart';
import 'product_detail_screen.dart';

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
              color: KivoDarkTheme.surface,
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
                                  Text('JMD \$${item.product.price.toStringAsFixed(2)}', style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: KivoDarkTheme.textSecondary),
                                  onPressed: () {
                                    marketplace.updateQuantity(item.product.id, item.quantity - 1);
                                    setSheetState(() {});
                                  },
                                ),
                                Text('${item.quantity}', style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 20, color: KivoDarkTheme.primaryEmerald),
                                  onPressed: () {
                                    marketplace.updateQuantity(item.product.id, item.quantity + 1);
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
                      const Text('Total (incl. GCT)', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 14)),
                      Text(
                        'JMD \$${marketplace.cartSubtotal.toStringAsFixed(2)}',
                        style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final success = marketplace.checkout(wallet);
                      if (success) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: KivoDarkTheme.surfaceElevated,
                            content: Text('Order Placed Successfully! Paid from Kivo Wallet.', style: TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold)),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Insufficient wallet balance to checkout.')),
                        );
                      }
                    },
                    child: const Text('Pay with Kivo Balance'),
                  ),
                ],
                const SizedBox(height: 16),
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
        title: const Text('Kivo Marketplace'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: marketplace.cartCount > 0,
              label: Text('${marketplace.cartCount}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () => _showCartSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Merchant POS Terminal Header Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PosCashierScreen())),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F382A), Color(0xFF13232F)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: KivoDarkTheme.primaryEmerald.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: KivoDarkTheme.primaryEmerald.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.point_of_sale, color: KivoDarkTheme.primaryEmerald, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Merchant POS Terminal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Accept Cash, Jam-Dex QR & Print Receipts', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: KivoDarkTheme.primaryEmerald),
                  ],
                ),
              ),
            ),
          ),

          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              onChanged: marketplace.setSearchQuery,
              style: const TextStyle(color: KivoDarkTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search Jamaican coffee, produce, crafts...',
                prefixIcon: Icon(Icons.search, color: KivoDarkTheme.textSecondary),
              ),
            ),
          ),

          // 2. Category Filter Pills
          SizedBox(
            height: 44,
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

          const SizedBox(height: 12),

          // 3. Product Grid
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
                      childAspectRatio: 0.72,
                    ),
                    itemCount: marketplace.filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = marketplace.filteredProducts[index];
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
                        child: Card(
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
                                      style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      p.sellerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'JMD \$${p.price.toStringAsFixed(0)}',
                                          style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.w800, fontSize: 14),
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

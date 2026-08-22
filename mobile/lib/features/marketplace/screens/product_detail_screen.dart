import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/dark_theme.dart';
import '../../../core/services/marketplace_provider.dart';
import '../../../core/services/wallet_provider.dart';
import 'merchant_store_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  void _showDeliveryCheckoutModal(BuildContext context) {
    final marketplace = context.read<MarketplaceProvider>();
    final wallet = context.read<WalletProvider>();
    final merchant = marketplace.getMerchant(product.merchantId) ??
        MerchantProfile(
          id: product.merchantId,
          name: product.sellerName,
          handle: '@${product.sellerName.toLowerCase().replaceAll(' ', '')}',
          description: 'Verified Jamaican Merchant on Kivo.',
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
          bannerUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800',
          phone: '+1 (876) 555-0100',
          parish: 'St. Andrew',
          town: 'New Kingston',
        );

    String selectedParish = 'Kingston';
    List<String> availableTowns = MarketplaceProvider.townsByParish[selectedParish] ?? ['Downtown Kingston'];
    String selectedTown = availableTowns.first;
    List<String> availableDistricts = MarketplaceProvider.districtsByTown[selectedTown] ?? ['General District'];
    String selectedDistrict = availableDistricts.first;
    final addressController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KivoDarkTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final eligibility = marketplace.checkDeliveryEligibility(product.merchantId, selectedParish);
          final bool isAllowed = eligibility['allowed'] == true;
          final double deliveryFee = (eligibility['fee'] as num?)?.toDouble() ?? 0.0;
          final bool isPickupOnly = eligibility['isPickupOnly'] == true;
          final double totalAmount = product.price + (isAllowed && !isPickupOnly ? deliveryFee : 0.0);

          return Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Delivery & Order Confirmation',
                        style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Product & Merchant Summary Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: KivoDarkTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: KivoDarkTheme.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl,
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
                              Text(product.name, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                              Text('Sold by: ${product.sellerName}', style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 11, fontWeight: FontWeight.w600)),
                              Text('Product: JMD \$${product.price.toStringAsFixed(2)}', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. Select Parish
                  const Text('1. Select Delivery Parish 🇯🇲', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: KivoDarkTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KivoDarkTheme.surfaceBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedParish,
                        isExpanded: true,
                        dropdownColor: KivoDarkTheme.surfaceElevated,
                        items: MarketplaceProvider.jamaicanParishes.map((parish) {
                          return DropdownMenuItem(
                            value: parish,
                            child: Text(parish, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (newParish) {
                          if (newParish != null) {
                            setModalState(() {
                              selectedParish = newParish;
                              availableTowns = MarketplaceProvider.townsByParish[newParish] ?? [newParish];
                              selectedTown = availableTowns.first;
                              availableDistricts = MarketplaceProvider.districtsByTown[selectedTown] ?? ['General District'];
                              selectedDistrict = availableDistricts.first;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Select Town
                  const Text('2. Select Town / Area', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: KivoDarkTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KivoDarkTheme.surfaceBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedTown,
                        isExpanded: true,
                        dropdownColor: KivoDarkTheme.surfaceElevated,
                        items: availableTowns.map((town) {
                          return DropdownMenuItem(
                            value: town,
                            child: Text(town, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (newTown) {
                          if (newTown != null) {
                            setModalState(() {
                              selectedTown = newTown;
                              availableDistricts = MarketplaceProvider.districtsByTown[newTown] ?? ['General District'];
                              selectedDistrict = availableDistricts.first;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Select District / Community
                  const Text('3. Select District / Community', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: KivoDarkTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KivoDarkTheme.surfaceBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: availableDistricts.contains(selectedDistrict) ? selectedDistrict : availableDistricts.first,
                        isExpanded: true,
                        dropdownColor: KivoDarkTheme.surfaceElevated,
                        items: availableDistricts.map((dist) {
                          return DropdownMenuItem(
                            value: dist,
                            child: Text(dist, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (newDist) {
                          if (newDist != null) {
                            setModalState(() => selectedDistrict = newDist);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Street Address Details
                  TextField(
                    controller: addressController,
                    style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Street Address / Landmark / Apt #',
                      labelStyle: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12),
                      filled: true,
                      fillColor: KivoDarkTheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: KivoDarkTheme.surfaceBorder)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Merchant Delivery Restriction Status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAllowed
                          ? KivoDarkTheme.primaryEmerald.withOpacity(0.12)
                          : isPickupOnly
                              ? KivoDarkTheme.accentAmber.withOpacity(0.12)
                              : KivoDarkTheme.accentRose.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAllowed
                            ? KivoDarkTheme.primaryEmerald
                            : isPickupOnly
                                ? KivoDarkTheme.accentAmber
                                : KivoDarkTheme.accentRose,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isAllowed ? Icons.local_shipping : (isPickupOnly ? Icons.store : Icons.warning_amber),
                          color: isAllowed ? KivoDarkTheme.primaryEmerald : (isPickupOnly ? KivoDarkTheme.accentAmber : KivoDarkTheme.accentRose),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            eligibility['message'] as String,
                            style: TextStyle(
                              color: isAllowed ? KivoDarkTheme.primaryEmerald : (isPickupOnly ? KivoDarkTheme.accentAmber : KivoDarkTheme.accentRose),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price Breakdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Product Price:', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13)),
                      Text('JMD \$${product.price.toStringAsFixed(2)}', style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery Courier Fee:', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13)),
                      Text(
                        isPickupOnly ? 'FREE (In-Store Pickup)' : 'JMD \$${deliveryFee.toStringAsFixed(2)}',
                        style: TextStyle(color: isAllowed ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.accentRose, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(color: KivoDarkTheme.surfaceBorder, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        'JMD \$${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Confirm & Pay Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (isAllowed || isPickupOnly) ? KivoDarkTheme.primaryEmerald : Colors.grey.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: (!isAllowed && !isPickupOnly)
                          ? null
                          : () {
                              if (wallet.jmdBalance >= totalAmount) {
                                wallet.sendMoney(
                                  product.sellerName,
                                  totalAmount,
                                  'Purchase: ${product.name} (Delivery to $selectedDistrict, $selectedTown, $selectedParish)',
                                );
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: KivoDarkTheme.surfaceElevated,
                                    content: Text(
                                      'Order confirmed! JMD \$${totalAmount.toStringAsFixed(2)} paid to ${product.sellerName}. Dispatching to $selectedDistrict, $selectedTown.',
                                      style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Colors.redAccent,
                                    content: Text('Insufficient wallet balance. Please top up your Kivo balance first.'),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.payment, color: Colors.black),
                      label: Text(
                        (isAllowed || isPickupOnly) ? 'PAY WITH KIVO WALLET' : 'DELIVERY NOT AVAILABLE',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marketplace = context.watch<MarketplaceProvider>();
    final merchant = marketplace.getMerchant(product.merchantId) ??
        MerchantProfile(
          id: product.merchantId,
          name: product.sellerName,
          handle: '@${product.sellerName.toLowerCase().replaceAll(' ', '')}',
          description: 'Verified Jamaican Merchant on Kivo.',
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
          bannerUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800',
          phone: '+1 (876) 555-0100',
          parish: 'St. Andrew',
          town: 'New Kingston',
        );

    return Scaffold(
      backgroundColor: KivoDarkTheme.background,
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Hero Image
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
                  // Category & Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${product.rating} (${product.reviewsCount} reviews)',
                            style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Product Title & Price
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: KivoDarkTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'JMD \$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: KivoDarkTheme.primaryEmerald),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text('Description', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Merchant Store Link & Name Card
                  const Text('Sold & Dispatched by Merchant', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MerchantStoreScreen(merchant: merchant)),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: KivoDarkTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: KivoDarkTheme.primaryEmerald.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundImage: CachedNetworkImageProvider(merchant.avatarUrl),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        merchant.name,
                                        style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified, color: KivoDarkTheme.primaryEmerald, size: 16),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${merchant.town}, ${merchant.parish} • View full catalog →',
                                  style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: KivoDarkTheme.primaryEmerald, size: 14),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            marketplace.addToCart(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Added ${product.name} to cart!')),
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart, color: KivoDarkTheme.primaryEmerald),
                          label: const Text('Add to Cart', style: TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: KivoDarkTheme.primaryEmerald),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showDeliveryCheckoutModal(context),
                          icon: const Icon(Icons.bolt, color: Colors.black),
                          label: const Text('Buy with Delivery', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KivoDarkTheme.primaryEmerald,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
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

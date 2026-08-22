import 'package:flutter/material.dart';
import 'wallet_provider.dart';

class MerchantProfile {
  final String id;
  final String name;
  final String handle;
  final String description;
  final String avatarUrl;
  final String bannerUrl;
  final double rating;
  final int reviewsCount;
  final String phone;
  final String parish;
  final String town;
  final String deliveryType; // 'all_island', 'specific_parishes', 'pickup_only'
  final List<String> allowedParishes;
  final double standardDeliveryFee;
  final bool isVerified;

  MerchantProfile({
    required this.id,
    required this.name,
    required this.handle,
    required this.description,
    required this.avatarUrl,
    required this.bannerUrl,
    this.rating = 4.9,
    this.reviewsCount = 48,
    required this.phone,
    required this.parish,
    required this.town,
    this.deliveryType = 'all_island',
    this.allowedParishes = const [],
    this.standardDeliveryFee = 650.0,
    this.isVerified = true,
  });
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final double rating;
  final int reviewsCount;
  final String merchantId;
  final String sellerName;
  final bool isFeatured;
  final String deliveryPolicy; // 'All-Island Delivery', 'Kingston & St. Andrew Only', 'Pickup Only'

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    this.rating = 4.8,
    this.reviewsCount = 24,
    required this.merchantId,
    required this.sellerName,
    this.isFeatured = false,
    this.deliveryPolicy = 'All-Island Delivery (JMD \$650)',
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

class DeliveryLocation {
  final String parish;
  final String town;
  final String district;
  final String streetAddress;
  final String deliveryNotes;

  DeliveryLocation({
    required this.parish,
    required this.town,
    required this.district,
    required this.streetAddress,
    this.deliveryNotes = '',
  });
}

class MarketplaceProvider extends ChangeNotifier {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  final List<String> categories = [
    'All',
    'Local Produce & Agro',
    'Food & Baked Goods',
    'Fashion & Crafts',
    'Electronics',
    'Services',
  ];

  // 14 Jamaican Parishes
  static const List<String> jamaicanParishes = [
    'Kingston',
    'St. Andrew',
    'St. Catherine',
    'Clarendon',
    'Manchester',
    'St. Elizabeth',
    'Westmoreland',
    'Hanover',
    'St. James',
    'Trelawny',
    'St. Ann',
    'St. Mary',
    'Portland',
    'St. Thomas',
  ];

  // Jamaican Towns mapped by Parish
  static const Map<String, List<String>> townsByParish = {
    'Kingston': ['Downtown Kingston', 'Port Royal', 'New Kingston', 'Norman Gardens'],
    'St. Andrew': ['Half-Way-Tree', 'Liguanea', 'Constant Spring', 'Barbican', 'Papine', 'Mona', 'Stony Hill', 'Meadowbrook'],
    'St. Catherine': ['Portmore', 'Spanish Town', 'Old Harbour', 'Linstead', 'Bog Walk', 'Ewarton'],
    'Clarendon': ['May Pen', 'Lionel Town', 'Frankfield', 'Hayes', 'Spaldings'],
    'Manchester': ['Mandeville', 'Christiana', 'Porus', 'Williamsfield', 'Mile Gully'],
    'St. Elizabeth': ['Santa Cruz', 'Black River', 'Junction', 'Southfield', 'Balaclava'],
    'Westmoreland': ['Savanna-la-Mar', 'Negril', 'Grange Hill', 'Darliston', 'Petersfield'],
    'Hanover': ['Lucea', 'Hopewell', 'Sandy Bay', 'Green Island'],
    'St. James': ['Montego Bay', 'Anchovy', 'Cambridge', 'Adelphi'],
    'Trelawny': ['Falmouth', 'Duncans', 'Clark\'s Town', 'Albert Town'],
    'St. Ann': ['Ocho Rios', 'St. Ann\'s Bay', 'Brown\'s Town', 'Runaway Bay', 'Claremont'],
    'St. Mary': ['Port Maria', 'Highgate', 'Annotto Bay', 'Oracabessa', 'Richmond'],
    'Portland': ['Port Antonio', 'Buff Bay', 'Manchioneal', 'Hope Bay', 'Boston Bay'],
    'St. Thomas': ['Morant Bay', 'Yallahs', 'Seaforth', 'Golden Grove', 'Bath'],
  };

  // Jamaican Districts mapped by Town
  static const Map<String, List<String>> districtsByTown = {
    'New Kingston': ['Knutsford Boulevard', 'Trafalgar Park', 'Pegasus Area', 'Chelsea Avenue'],
    'Half-Way-Tree': ['Clock Tower Plaza', 'Southdale', 'Eastwood Park', 'Cassia Park'],
    'Liguanea': ['Lane Plaza', 'Sovereign Centre', 'Hope Pastures', 'Widcombe'],
    'Barbican': ['Barbican Square', 'Widcombe Heights', 'Russell Heights', 'Fontana Area'],
    'Portmore': ['Greater Portmore', 'Edgewater', 'Bridgeport', 'Garfield', 'Braeton', 'Bayside'],
    'Spanish Town': ['Twickenham Park', 'Greendale', 'Brunswick', 'St. Jago Heights'],
    'Mandeville': ['Golf View', 'Bloomfield', 'Ingleside', 'Hattfield', 'Greenvale'],
    'Montego Bay': ['Ironshore', 'Rose Hall', 'Gloucester Avenue', 'Westgate', 'Bogue'],
    'Ocho Rios': ['Main Street', 'Shaw Park', 'Content Gardens', 'Exchange', 'Buckfield'],
    'Negril': ['West End', 'Norman Manley Boulevard', 'Sheffield', 'Orange Bay'],
  };

  final List<MerchantProfile> _merchants = [
    MerchantProfile(
      id: 'merch_mavis',
      name: 'Mavis Bank Agro Co.',
      handle: '@mavisbankagro',
      description: 'Purveyors of Grade 1 certified 100% Jamaican Blue Mountain Coffee and high-altitude spices.',
      avatarUrl: 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=500',
      bannerUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800',
      rating: 4.9,
      reviewsCount: 142,
      phone: '+1 (876) 993-2210',
      parish: 'St. Andrew',
      town: 'Stony Hill',
      deliveryType: 'all_island',
      allowedParishes: jamaicanParishes,
      standardDeliveryFee: 650.0,
    ),
    MerchantProfile(
      id: 'merch_trenchtown',
      name: 'Trench Town Artisans',
      handle: '@trenchtowncrafts',
      description: 'Authentic handmade Jamaican leathercrafts, cedar wood sculptures, and cultural artifacts.',
      avatarUrl: 'https://images.unsplash.com/photo-1627123424574-724758594e93?w=500',
      bannerUrl: 'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?w=800',
      rating: 4.8,
      reviewsCount: 38,
      phone: '+1 (876) 701-4492',
      parish: 'Kingston',
      town: 'Downtown Kingston',
      deliveryType: 'specific_parishes',
      allowedParishes: ['Kingston', 'St. Andrew', 'St. Catherine'],
      standardDeliveryFee: 500.0,
    ),
    MerchantProfile(
      id: 'merch_keisha',
      name: 'Keisha Kingston Bakes',
      handle: '@keishabakes',
      description: 'Artisanal Kingston bakery specializing in traditional rum cakes, spiced beef patties, and pastries.',
      avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      bannerUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800',
      rating: 5.0,
      reviewsCount: 84,
      phone: '+1 (876) 431-7788',
      parish: 'St. Andrew',
      town: 'New Kingston',
      deliveryType: 'specific_parishes',
      allowedParishes: ['Kingston', 'St. Andrew', 'St. Catherine'],
      standardDeliveryFee: 400.0,
    ),
    MerchantProfile(
      id: 'merch_islandtech',
      name: 'Island Tech Depot',
      handle: '@islandtech',
      description: 'Consumer electronics, solar energy backup power banks, smart chargers, and accessories.',
      avatarUrl: 'https://images.unsplash.com/photo-1609091839311-d5368f9bc14a?w=500',
      bannerUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800',
      rating: 4.7,
      reviewsCount: 89,
      phone: '+1 (876) 812-3309',
      parish: 'St. James',
      town: 'Montego Bay',
      deliveryType: 'all_island',
      allowedParishes: jamaicanParishes,
      standardDeliveryFee: 750.0,
    ),
    MerchantProfile(
      id: 'merch_mamagrace',
      name: 'Mama Grace Spices',
      handle: '@mamagracespices',
      description: 'Fiery scotch bonnet pepper sauces, allspice pimento seasonings, and jerk marinades from St. Elizabeth.',
      avatarUrl: 'https://images.unsplash.com/photo-1588854337236-6889d631faa8?w=500',
      bannerUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=800',
      rating: 5.0,
      reviewsCount: 215,
      phone: '+1 (876) 620-8811',
      parish: 'St. Elizabeth',
      town: 'Santa Cruz',
      deliveryType: 'all_island',
      allowedParishes: jamaicanParishes,
      standardDeliveryFee: 650.0,
    ),
    MerchantProfile(
      id: 'merch_kestrel',
      name: 'Kestrel Advisory Group',
      handle: '@kestreladvisory',
      description: 'Certified public accountants offering TAJ GCT-03 compliance, payroll, and business consulting.',
      avatarUrl: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=500',
      bannerUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800',
      rating: 4.9,
      reviewsCount: 19,
      phone: '+1 (876) 555-0100',
      parish: 'St. Andrew',
      town: 'New Kingston',
      deliveryType: 'pickup_only',
      allowedParishes: [],
      standardDeliveryFee: 0.0,
    ),
  ];

  final List<Product> _products = [
    Product(
      id: 'prod-1',
      name: 'Jamaican Blue Mountain Coffee (1lb)',
      description: '100% Certified Grade 1 Whole Bean Coffee from the highest peaks of the Blue Mountains.',
      price: 3200.00,
      category: 'Local Produce & Agro',
      imageUrl: 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=500',
      rating: 4.9,
      reviewsCount: 142,
      merchantId: 'merch_mavis',
      sellerName: 'Mavis Bank Agro Co.',
      isFeatured: true,
      deliveryPolicy: 'All-Island Delivery (JMD \$650)',
    ),
    Product(
      id: 'prod-1b',
      name: 'Blue Mountain Peaberry Reserve (8oz)',
      description: 'Rare single-bean harvest with intense caramel aroma and silky finish.',
      price: 2400.00,
      category: 'Local Produce & Agro',
      imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=500',
      rating: 5.0,
      reviewsCount: 31,
      merchantId: 'merch_mavis',
      sellerName: 'Mavis Bank Agro Co.',
      deliveryPolicy: 'All-Island Delivery (JMD \$650)',
    ),
    Product(
      id: 'prod-2',
      name: 'Handcrafted Kingston Leather Wallet',
      description: 'Genuine hand-stitched Jamaican leather with RFID blocking and coin pocket.',
      price: 4500.00,
      category: 'Fashion & Crafts',
      imageUrl: 'https://images.unsplash.com/photo-1627123424574-724758594e93?w=500',
      rating: 4.8,
      reviewsCount: 38,
      merchantId: 'merch_trenchtown',
      sellerName: 'Trench Town Artisans',
      isFeatured: true,
      deliveryPolicy: 'Kingston, St. Andrew & St. Catherine Delivery',
    ),
    Product(
      id: 'prod-2b',
      name: 'Carved Cedar Rasta Drum & Shaker',
      description: 'Hand-tuned ceremonial Jamaican cedar drum with goat skin head.',
      price: 9500.00,
      category: 'Fashion & Crafts',
      imageUrl: 'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?w=500',
      rating: 4.9,
      reviewsCount: 17,
      merchantId: 'merch_trenchtown',
      sellerName: 'Trench Town Artisans',
      deliveryPolicy: 'Kingston, St. Andrew & St. Catherine Delivery',
    ),
    Product(
      id: 'prod-cake-1',
      name: 'Kingston Spiced Rum Cake (Medium)',
      description: 'Rich dark fruit cake infused with aged Jamaican rum and island spices.',
      price: 3800.00,
      category: 'Food & Baked Goods',
      imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=500',
      rating: 5.0,
      reviewsCount: 48,
      merchantId: 'merch_keisha',
      sellerName: 'Keisha Kingston Bakes',
      isFeatured: true,
      deliveryPolicy: 'Kingston, St. Andrew & St. Catherine (JMD \$400)',
    ),
    Product(
      id: 'prod-cake-2',
      name: 'Cocktail Cocktail Patties (Box of 12)',
      description: 'Flaky crust cocktail patties filled with spicy Jamaican beef, callaloo, and chicken.',
      price: 2600.00,
      category: 'Food & Baked Goods',
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500',
      rating: 4.9,
      reviewsCount: 36,
      merchantId: 'merch_keisha',
      sellerName: 'Keisha Kingston Bakes',
      deliveryPolicy: 'Kingston, St. Andrew & St. Catherine (JMD \$400)',
    ),
    Product(
      id: 'prod-3',
      name: 'Solar Power Bank 20,000mAh',
      description: 'Fast charging portable rugged power bank with dual USB-C output and LED flashlight.',
      price: 5800.00,
      category: 'Electronics',
      imageUrl: 'https://images.unsplash.com/photo-1609091839311-d5368f9bc14a?w=500',
      rating: 4.7,
      reviewsCount: 89,
      merchantId: 'merch_islandtech',
      sellerName: 'Island Tech Depot',
      deliveryPolicy: 'All-Island Delivery (JMD \$750)',
    ),
    Product(
      id: 'prod-4',
      name: 'Scotch Bonnet Hot Pepper Sauce (Pack of 3)',
      description: 'Authentic fiery Jamaican home recipe made with fresh St. Elizabeth scotch bonnet peppers.',
      price: 1800.00,
      category: 'Local Produce & Agro',
      imageUrl: 'https://images.unsplash.com/photo-1588854337236-6889d631faa8?w=500',
      rating: 5.0,
      reviewsCount: 215,
      merchantId: 'merch_mamagrace',
      sellerName: 'Mama Grace Spices',
      isFeatured: true,
      deliveryPolicy: 'All-Island Delivery (JMD \$650)',
    ),
    Product(
      id: 'prod-5',
      name: 'QuickBooks & TAJ Tax Consultation',
      description: '1-Hour remote session with a certified Jamaican tax accountant to prepare GCT-03 returns.',
      price: 8500.00,
      category: 'Services',
      imageUrl: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=500',
      rating: 4.9,
      reviewsCount: 19,
      merchantId: 'merch_kestrel',
      sellerName: 'Kestrel Advisory Group',
      deliveryPolicy: 'Digital Delivery / In-Office Consultation',
    ),
  ];

  final Map<String, CartItem> _cart = {};

  List<CartItem> get cartItems => _cart.values.toList();
  int get cartCount => _cart.values.fold(0, (sum, item) => sum + item.quantity);
  double get cartSubtotal => _cart.values.fold(0.0, (sum, item) => sum + item.total);

  List<Product> get allProducts => _products;
  List<Product> get products => _products;
  List<MerchantProfile> get merchants => _merchants;

  List<Product> get filteredProducts {
    return _products.where((product) {
      final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.sellerName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  /// Get all products from a single merchant
  List<Product> getProductsByMerchant(String merchantNameOrId) {
    return _products.where((p) => p.merchantId == merchantNameOrId || p.sellerName.toLowerCase() == merchantNameOrId.toLowerCase()).toList();
  }

  MerchantProfile? getMerchant(String merchantNameOrId) {
    try {
      return _merchants.firstWhere(
        (m) => m.id == merchantNameOrId || m.name.toLowerCase() == merchantNameOrId.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Validate delivery eligibility for a target merchant & parish
  Map<String, dynamic> checkDeliveryEligibility(String merchantIdOrName, String parish) {
    final merchant = getMerchant(merchantIdOrName);
    if (merchant == null) {
      return {'allowed': true, 'fee': 650.0, 'message': 'Standard Island Delivery'};
    }

    if (merchant.deliveryType == 'pickup_only') {
      return {
        'allowed': false,
        'fee': 0.0,
        'message': '${merchant.name} offers In-Store Pickup Only at ${merchant.town}, ${merchant.parish}.',
        'isPickupOnly': true,
      };
    }

    if (merchant.deliveryType == 'all_island' || merchant.allowedParishes.contains(parish)) {
      return {
        'allowed': true,
        'fee': merchant.standardDeliveryFee,
        'message': 'Delivery available to $parish via ${merchant.name} partner courier (JMD \$${merchant.standardDeliveryFee.toStringAsFixed(0)})',
      };
    } else {
      return {
        'allowed': false,
        'fee': 0.0,
        'message': '${merchant.name} currently only delivers to: ${merchant.allowedParishes.join(", ")}. Please choose in-store pickup or a different address.',
      };
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void addToCart(Product product) {
    if (_cart.containsKey(product.id)) {
      _cart[product.id]!.quantity += 1;
    } else {
      _cart[product.id] = CartItem(product: product);
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    if (_cart.containsKey(productId)) {
      if (_cart[productId]!.quantity > 1) {
        _cart[productId]!.quantity -= 1;
      } else {
        _cart.remove(productId);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Future<bool> checkoutWithKivo({
    required WalletProvider wallet,
    required DeliveryLocation deliveryLocation,
    double deliveryFee = 0.0,
  }) async {
    final grandTotal = cartSubtotal + deliveryFee;
    if (wallet.jmdBalance < grandTotal) return false;

    // Send money to primary merchant
    final firstItem = _cart.values.isNotEmpty ? _cart.values.first.product : null;
    final merchantName = firstItem?.sellerName ?? 'Kivo Marketplace Merchant';

    wallet.sendMoney(
      merchantName,
      grandTotal,
      'Order: $cartCount items to ${deliveryLocation.district}, ${deliveryLocation.town}, ${deliveryLocation.parish}',
    );

    clearCart();
    return true;
  }
}

import 'package:flutter/material.dart';
import 'wallet_provider.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final double rating;
  final int reviewsCount;
  final String sellerName;
  final bool isFeatured;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    this.rating = 4.8,
    this.reviewsCount = 24,
    required this.sellerName,
    this.isFeatured = false,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

class MarketplaceProvider extends ChangeNotifier {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  final List<String> categories = [
    'All',
    'Local Produce & Agro',
    'Electronics',
    'Fashion & Crafts',
    'Services',
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
      sellerName: 'Mavis Bank Agro Co.',
      isFeatured: true,
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
      sellerName: 'Trench Town Artisans',
      isFeatured: true,
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
      sellerName: 'Island Tech Depot',
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
      sellerName: 'Mama Grace Spices',
      isFeatured: true,
    ),
    Product(
      id: 'prod-5',
      name: 'QuickBooks & TAJ Tax Filing Consultation',
      description: '1-Hour remote session with a certified Jamaican tax accountant to prepare GCT-03 returns.',
      price: 8500.00,
      category: 'Services',
      imageUrl: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=500',
      rating: 4.9,
      reviewsCount: 19,
      sellerName: 'Kestrel Advisory Group',
    ),
  ];

  final Map<String, CartItem> _cart = {};

  List<CartItem> get cartItems => _cart.values.toList();
  int get cartCount => _cart.values.fold(0, (sum, item) => sum + item.quantity);
  double get cartSubtotal => _cart.values.fold(0.0, (sum, item) => sum + item.total);

  List<Product> get allProducts => _products;
  List<Product> get products => _products;

  List<Product> get filteredProducts {
    return _products.where((product) {
      final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void setCategory(String cat) {
    _selectedCategory = cat;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void addToCart(Product product) {
    if (_cart.containsKey(product.id)) {
      _cart[product.id]!.quantity++;
    } else {
      _cart[product.id] = CartItem(product: product);
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (!_cart.containsKey(productId)) return;
    if (quantity <= 0) {
      _cart.remove(productId);
    } else {
      _cart[productId]!.quantity = quantity;
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  bool checkout(WalletProvider wallet) {
    if (wallet.jmdBalance < cartSubtotal) return false;
    wallet.sendMoney('Kivo Marketplace', cartSubtotal, 'Order #${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    clearCart();
    return true;
  }
}

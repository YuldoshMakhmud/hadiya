import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/cart_item.dart';

class AppProvider extends ChangeNotifier {
  bool _isKorea = true;
  bool _isWon = true;
  bool _isLoggedIn = false;
  String _userName = '';
  String _userEmail = '';
  final List<CartItem> _cart = [];
  final List<Product> _wishlist = [];
  String? _selectedCategory; // null = "Barchasi"

  // Products from Firestore
  List<Product> _products = [];
  bool _productsLoading = true;
  StreamSubscription<QuerySnapshot>? _productsSub;

  bool get isKorea => _isKorea;
  bool get isWon => _isWon;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userEmail => _userEmail;
  List<CartItem> get cart => _cart;
  List<Product> get wishlist => _wishlist;
  String? get selectedCategory => _selectedCategory;
  List<Product> get allProductsList => _products;
  bool get productsLoading => _productsLoading;

  String get currencyLabel => _isWon ? '₩ Won' : "So'm";
  String get locationLabel => _isKorea ? '🇰🇷 Koreya' : '🇺🇿 O\'zbekiston';
  String get currencySymbol => _isWon ? '₩' : "so'm";

  int get cartCount => _cart.fold(0, (sum, item) => sum + item.quantity);

  double get cartTotal {
    return _cart.fold(0.0, (sum, item) {
      final price = _isWon ? item.product.priceKrw : item.product.priceUzs;
      return sum + price * item.quantity;
    });
  }

  String get cartTotalFormatted {
    final total = cartTotal;
    if (_isWon) {
      return '₩${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    } else {
      return "${(total / 1000).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ming so'm";
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _isKorea = prefs.getBool('isKorea') ?? true;
    _isWon = prefs.getBool('isWon') ?? true;
    _userName = prefs.getString('userName') ?? '';
    _userEmail = prefs.getString('userEmail') ?? '';
    notifyListeners();
    _loadProducts();
  }

  void _loadProducts() {
    try {
      _productsSub = FirebaseFirestore.instance
          .collection('products')
          .snapshots()
          .listen((snap) {
        _products = snap.docs.map((d) {
          final data = d.data();
          return Product(
            id: d.id,
            name: data['name'] as String? ?? '',
            description: data['description'] as String? ?? '',
            priceKrw: (data['priceKrw'] as num? ?? 0).toDouble(),
            priceUzs: (data['priceUzs'] as num? ?? 0).toDouble(),
            category: data['category'] as String? ?? '',
            imageUrl: data['imageUrl'] as String? ?? '',
            isNew: data['isNew'] == true,
            isBestSeller: data['isBestSeller'] == true,
          );
        }).toList();
        _productsLoading = false;
        notifyListeners();
      }, onError: (e) {
        debugPrint('AppProvider products error: $e');
        _products = [];
        _productsLoading = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('AppProvider init error: $e');
      _products = [];
      _productsLoading = false;
      notifyListeners();
    }
  }

  Future<void> setCountry(bool isKorea) async {
    _isKorea = isKorea;
    _isWon = isKorea;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isKorea', isKorea);
    await prefs.setBool('isWon', isKorea);
    notifyListeners();
  }

  Future<void> toggleCurrency() async {
    _isWon = !_isWon;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isWon', _isWon);
    notifyListeners();
  }

  Future<void> login(String name, String email) async {
    _userName = name;
    _userEmail = email;
    _isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userName = '';
    _userEmail = '';
    _cart.clear();
    _wishlist.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    notifyListeners();
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void addToCart(Product product) {
    final index = _cart.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _cart[index].quantity++;
    } else {
      _cart.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateCartQuantity(String productId, int quantity) {
    final index = _cart.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index].quantity = quantity;
      }
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  void toggleWishlist(Product product) {
    final index = _wishlist.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _wishlist.removeAt(index);
    } else {
      _wishlist.add(product);
    }
    notifyListeners();
  }

  bool isInWishlist(String productId) {
    return _wishlist.any((p) => p.id == productId);
  }

  List<Product> get filteredProducts {
    if (_selectedCategory == null) return _products;
    return _products.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    super.dispose();
  }
}

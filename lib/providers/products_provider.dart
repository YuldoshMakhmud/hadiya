import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String _selectedCategory = 'Barchasi';
  StreamSubscription<QuerySnapshot>? _sub;

  List<Map<String, dynamic>> get products => _filteredProducts;
  List<Map<String, dynamic>> get allProductsList => _products;
  bool get loading => _loading;
  String get selectedCategory => _selectedCategory;

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedCategory == 'Barchasi') return _products;
    return _products
        .where((p) => p['category'] == _selectedCategory)
        .toList();
  }

  ProductsProvider() {
    _loadFromFirestore();
  }

  void _loadFromFirestore() {
    try {
      _sub = FirebaseFirestore.instance
          .collection('products')
          .snapshots()
          .listen((snap) {
        _products = snap.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        }).toList();
        _loading = false;
        notifyListeners();
      }, onError: (e) {
        debugPrint('ProductsProvider Firestore error: $e');
        _products = [];
        _loading = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('ProductsProvider init error: $e');
      _products = [];
      _loading = false;
      notifyListeners();
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

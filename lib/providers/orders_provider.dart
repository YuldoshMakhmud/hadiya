import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  /// Buyurtma yaratish — Firestore'ga saqlaydi
  Future<String?> createOrder({
    required List<Map<String, dynamic>> items,
    required String currency,
    required double total,
    required String userName,
    required String userEmail,
    required String contact,
    required String address,
    String? comment,
    String? receiptUrl,
    String? telegramUsername,
    String? telegramUserId,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final docRef =
          await FirebaseFirestore.instance.collection('orders').add({
        'items': items,
        'currency': currency,
        'finalPrice': total,
        'userName': userName,
        'userEmail': userEmail,
        'userPhone': contact,
        'address': address,
        'comment': comment ?? '',
        'receiptUrl': receiptUrl ?? '',
        'telegramUsername': telegramUsername ?? '',
        'telegramUserId': telegramUserId ?? '',
        'status': 'yangi',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _loading = false;
      notifyListeners();
      return docRef.id;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  /// Admin uchun — barcha buyurtmalar
  Stream<QuerySnapshot> getOrders() {
    return FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Foydalanuvchining o'z buyurtmalari (email bo'yicha)
  Stream<QuerySnapshot> getUserOrders(String userEmail) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('userEmail', isEqualTo: userEmail)
        .snapshots();
  }

  /// Status yangilash
  Future<void> updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(docId)
        .update({'status': status});
  }
}

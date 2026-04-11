import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';
import '../providers/app_provider.dart';
import '../providers/orders_provider.dart';

class OrdersScreen extends StatelessWidget {
  final bool embedded;
  const OrdersScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    Widget body = StreamBuilder<QuerySnapshot>(
      stream: context.read<OrdersProvider>().getUserOrders(provider.userEmail),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.grey),
                const SizedBox(height: 12),
                Text('Xatolik: ${snap.error}',
                    style: const TextStyle(color: AppColors.grey),
                    textAlign: TextAlign.center),
              ],
            ),
          );
        }

        final docs = snap.data?.docs ?? [];

        // Email bo'lmasa yoki buyurtma yo'q
        if (provider.userEmail.isEmpty) {
          return _emptyState(
            icon: Icons.person_outline,
            title: 'Login qilish kerak',
            subtitle: 'Buyurtmalarni ko\'rish uchun tizimga kiring',
          );
        }

        if (docs.isEmpty) {
          return _emptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Buyurtmalar yo\'q',
            subtitle: 'Birinchi buyurtmangizni bering!',
          );
        }

        // Dart'da createdAt bo'yicha tartiblaymiz
        final sorted = List.from(docs);
        sorted.sort((a, b) {
          final aT = (a.data() as Map)['createdAt'];
          final bT = (b.data() as Map)['createdAt'];
          if (aT is Timestamp && bT is Timestamp) {
            return bT.compareTo(aT);
          }
          return 0;
        });

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final doc = sorted[i];
            final data = doc.data() as Map<String, dynamic>;
            return _OrderCard(
              orderId: doc.id,
              data: data,
              isWon: provider.isWon,
            );
          },
        );
      },
    );

    if (embedded) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Buyurtmalarim'),
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.cream,
        ),
        body: body,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyurtmalarim'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.cream,
      ),
      body: body,
    );
  }

  Widget _emptyState(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 52, color: AppColors.primary),
          ),
          const SizedBox(height: 18),
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
          const SizedBox(height: 6),
          Text(subtitle,
              style:
                  const TextStyle(color: AppColors.grey, fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;
  final bool isWon;

  const _OrderCard({
    required this.orderId,
    required this.data,
    required this.isWon,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'yangi';
    final items = (data['items'] as List<dynamic>? ?? []);
    final total = (data['finalPrice'] as num?)?.toDouble() ?? 0;
    final address = data['address'] as String? ?? '';
    final comment = data['comment'] as String? ?? '';
    final hasReceipt = (data['receiptUrl'] as String? ?? '').isNotEmpty;
    final createdAt = data['createdAt'];

    // Sanani format qilish
    String dateStr = '';
    if (createdAt is Timestamp) {
      final d = createdAt.toDate();
      dateStr =
          '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }

    // Narxni format qilish
    String totalStr;
    if (isWon) {
      totalStr =
          '₩${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    } else {
      totalStr =
          '${(total / 1000).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ming so\'m';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_statusIcon(status),
                    size: 18, color: _statusColor(status)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${orderId.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primary),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(dateStr,
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 11)),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _statusText(status),
                  style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.w600,
                      fontSize: 11),
                ),
              ),
            ]),
          ),

          // ── Mahsulotlar ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...items.take(3).map((item) {
                  final m = item as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(children: [
                      const Icon(Icons.circle,
                          size: 5, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${m['name'] ?? ''} × ${m['quantity'] ?? 1}',
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${m['price'] ?? ''}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                      ),
                    ]),
                  );
                }),
                if (items.length > 3)
                  Text(
                    '+${items.length - 3} ta mahsulot',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),

          // ── Manzil + Jami ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (address.isNotEmpty) ...[
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(
                            color: AppColors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                ],
                if (comment.isNotEmpty) ...[
                  Row(children: [
                    const Icon(Icons.comment_outlined,
                        size: 14, color: AppColors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        comment,
                        style: const TextStyle(
                            color: AppColors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (hasReceipt)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long,
                                size: 12, color: Colors.green),
                            SizedBox(width: 4),
                            Text('Chek yuklangan',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )
                    else
                      const SizedBox(),
                    Text(
                      totalStr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'tasdiqlandi':
        return Colors.blue;
      case 'yetkazilmoqda':
        return AppColors.primary;
      case 'yetkazildi':
        return Colors.green;
      case 'bekor':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'tasdiqlandi':
        return Icons.check_circle_outline;
      case 'yetkazilmoqda':
        return Icons.local_shipping_outlined;
      case 'yetkazildi':
        return Icons.done_all_rounded;
      case 'bekor':
        return Icons.cancel_outlined;
      default:
        return Icons.access_time_rounded;
    }
  }

  String _statusText(String s) {
    switch (s) {
      case 'tasdiqlandi':
        return 'Tasdiqlandi';
      case 'yetkazilmoqda':
        return 'Yetkazilmoqda';
      case 'yetkazildi':
        return 'Yetkazildi';
      case 'bekor':
        return 'Bekor qilindi';
      default:
        return 'Yangi';
    }
  }
}

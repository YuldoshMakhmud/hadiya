import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.data,
  });

  // ── Helpers ────────────────────────────────────────────────────────
  String get _shortId => orderId.substring(0, 8).toUpperCase();

  String _formatDate(dynamic ts) {
    if (ts is! Timestamp) return '';
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}  '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatPrice(double total, String currency) {
    if (currency == 'KRW') {
      return '₩${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
    return "${(total / 1000).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ming so'm";
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'tasdiqlandi':   return Colors.blue;
      case 'yetkazilmoqda': return AppColors.primary;
      case 'yetkazildi':    return Colors.green;
      case 'bekor':         return Colors.red;
      default:              return Colors.orange;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'tasdiqlandi':   return Icons.check_circle_outline;
      case 'yetkazilmoqda': return Icons.local_shipping_outlined;
      case 'yetkazildi':    return Icons.done_all_rounded;
      case 'bekor':         return Icons.cancel_outlined;
      default:              return Icons.access_time_rounded;
    }
  }

  String _statusText(String s) {
    switch (s) {
      case 'tasdiqlandi':   return 'Tasdiqlandi';
      case 'yetkazilmoqda': return 'Yetkazilmoqda';
      case 'yetkazildi':    return 'Yetkazildi ✓';
      case 'bekor':         return 'Bekor qilindi';
      default:              return 'Yangi buyurtma';
    }
  }

  static const _steps = ['yangi', 'tasdiqlandi', 'yetkazilmoqda', 'yetkazildi'];

  @override
  Widget build(BuildContext context) {
    final status   = data['status']     as String? ?? 'yangi';
    final items    = (data['items']     as List<dynamic>? ?? []);
    final total    = (data['finalPrice'] as num?)?.toDouble() ?? 0;
    final currency = data['currency']   as String? ?? 'KRW';
    final userName = data['userName']   as String? ?? '';
    final phone    = data['userPhone']  as String? ?? '';
    final address  = data['address']    as String? ?? '';
    final comment  = data['comment']    as String? ?? '';
    final receipt  = data['receiptUrl'] as String? ?? '';
    final createdAt = data['createdAt'];

    final isCancelled = status == 'bekor';
    final stepIndex   = _steps.indexOf(status);

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.cream,
        elevation: 0,
        title: Text(
          '#$_shortId',
          style: const TextStyle(
              color: AppColors.cream,
              fontWeight: FontWeight.bold,
              fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: AppColors.cream),
            tooltip: 'ID nusxalash',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: orderId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Buyurtma ID nusxalandi'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Status card ──────────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_statusIcon(status),
                          color: _statusColor(status), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _statusText(status),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _statusColor(status),
                            ),
                          ),
                          if (_formatDate(createdAt).isNotEmpty)
                            Text(
                              _formatDate(createdAt),
                              style: const TextStyle(
                                  color: AppColors.grey, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ]),

                  // Qadam ko'rsatgich (bekor bo'lmagan holda)
                  if (!isCancelled) ...[
                    const SizedBox(height: 20),
                    _StatusStepper(
                        currentStep: stepIndex < 0 ? 0 : stepIndex),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Mahsulotlar ──────────────────────────────────────────
            _sectionTitle('🛍️ Buyurtma tarkibi'),
            _card(
              child: Column(
                children: items.map((item) {
                  final m = item as Map<String, dynamic>;
                  final name     = m['name']     as String? ?? '';
                  final qty      = m['quantity']  as int?    ?? 1;
                  final price    = m['price']     as String? ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text('$qty',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(name,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                      Text(price,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ]),
                  );
                }).toList()
                  ..insert(
                    items.length,
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Jami:',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          Text(
                            _formatPrice(total, currency),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Yetkazish ma'lumotlari ───────────────────────────────
            _sectionTitle('📍 Yetkazish ma\'lumotlari'),
            _card(
              child: Column(
                children: [
                  _infoRow(Icons.person_outline, 'Ism', userName),
                  if (phone.isNotEmpty)
                    _infoRow(Icons.phone_outlined, 'Telefon', phone),
                  if (address.isNotEmpty)
                    _infoRow(Icons.location_on_outlined, 'Manzil', address),
                  if (comment.isNotEmpty)
                    _infoRow(Icons.comment_outlined, 'Izoh', comment),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── To'lov cheki ─────────────────────────────────────────
            _sectionTitle('🧾 To\'lov cheki'),
            if (receipt.isNotEmpty)
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        receipt,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 80,
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: Text('Rasm yuklanmadi',
                                style: TextStyle(color: AppColors.grey)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 16),
                      const SizedBox(width: 6),
                      const Text('Chek yuklangan',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ]),
                  ],
                ),
              )
            else
              _card(
                child: Row(children: [
                  Icon(Icons.receipt_long_outlined,
                      color: Colors.grey.shade400, size: 20),
                  const SizedBox(width: 10),
                  const Text('Chek yuklanmagan',
                      style:
                          TextStyle(color: AppColors.grey, fontSize: 13)),
                ]),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primary),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: AppColors.grey),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2A2A2A))),
        ),
      ]),
    );
  }
}

// ── Status stepper ────────────────────────────────────────────────────
class _StatusStepper extends StatelessWidget {
  final int currentStep; // 0..3

  const _StatusStepper({required this.currentStep});

  static const _labels = ['Yangi', 'Tasdiqlandi', 'Yetkazilmoqda', 'Yetkazildi'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Chiziq
          final lineStep = i ~/ 2;
          final done = lineStep < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              color: done ? AppColors.primary : Colors.grey.shade200,
            ),
          );
        }
        // Doira
        final step = i ~/ 2;
        final done = step <= currentStep;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: done ? AppColors.primary : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                done ? Icons.check : Icons.circle,
                size: done ? 14 : 8,
                color: done ? Colors.white : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _labels[step],
              style: TextStyle(
                fontSize: 9,
                fontWeight:
                    step == currentStep ? FontWeight.bold : FontWeight.normal,
                color:
                    step == currentStep ? AppColors.primary : AppColors.grey,
              ),
            ),
          ],
        );
      }),
    );
  }
}

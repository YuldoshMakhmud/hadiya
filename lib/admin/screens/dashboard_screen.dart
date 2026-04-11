import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Umumiy ko'rsatkichlar",
                      style:
                          TextStyle(fontSize: 14, color: Color(0xFF888888)),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: Color(0xFF888888)),
                      const SizedBox(width: 8),
                      Text(
                        _today(),
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF555555)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Stats cards
            _StatsRow(),
            const SizedBox(height: 28),

            // Recent orders + products
            LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _RecentOrders()),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _ProductsList()),
                  ],
                );
              }
              return Column(
                children: [
                  _RecentOrders(),
                  const SizedBox(height: 20),
                  _ProductsList(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _today() {
    final now = DateTime.now();
    const months = [
      'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
      'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, ordersSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, productsSnap) {
            final orders = ordersSnap.data?.docs ?? [];
            final products = productsSnap.data?.docs ?? [];

            int totalOrders = orders.length;
            int newOrders = 0;
            int todayOrders = 0;
            final today = DateTime.now();

            for (final o in orders) {
              final data = o.data() as Map<String, dynamic>;
              final status = data['status'] as String? ?? 'yangi';
              if (status == 'yangi') newOrders++;

              try {
                final ts = data['createdAt'] as Timestamp?;
                if (ts != null) {
                  final dt = ts.toDate();
                  if (dt.year == today.year &&
                      dt.month == today.month &&
                      dt.day == today.day) {
                    todayOrders++;
                  }
                }
              } catch (_) {}
            }

            return LayoutBuilder(builder: (ctx, constraints) {
              final isWide = constraints.maxWidth > 700;
              final cards = [
                _StatCard(
                  title: 'Jami buyurtmalar',
                  value: '$totalOrders',
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFF1A5C52),
                  bg: const Color(0xFFE8F3F1),
                ),
                _StatCard(
                  title: 'Yangi buyurtmalar',
                  value: '$newOrders',
                  subtitle: 'kutilmoqda',
                  icon: Icons.hourglass_top_outlined,
                  color: const Color(0xFFB8963E),
                  bg: const Color(0xFFFFF8EC),
                ),
                _StatCard(
                  title: 'Jami mahsulotlar',
                  value: '${products.length}',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF5B8DEF),
                  bg: const Color(0xFFEEF3FF),
                ),
                _StatCard(
                  title: 'Bugungi buyurtmalar',
                  value: '$todayOrders',
                  icon: Icons.today_outlined,
                  color: const Color(0xFF34C759),
                  bg: const Color(0xFFEFFAF1),
                ),
              ];

              if (isWide) {
                return Row(
                  children: cards
                      .map((c) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: c,
                            ),
                          ))
                      .toList(),
                );
              }
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: cards,
              );
            });
          },
        );
      },
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Color bg;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    subtitle!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF888888)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }
}

// ─── Recent Orders ────────────────────────────────────────────────────────────

class _RecentOrders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              'Oxirgi buyurtmalar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .orderBy('createdAt', descending: true)
                .limit(8)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF1A5C52))),
                );
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text("Buyurtmalar yo'q",
                        style: TextStyle(color: Color(0xFF888888))),
                  ),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return _OrderRow(
                    orderId: doc.id.substring(0, 8).toUpperCase(),
                    name: d['userName'] ?? 'Mehmon',
                    total: (d['finalPrice'] as num? ?? 0).toDouble(),
                    currency: d['currency'] ?? 'UZS',
                    status: d['status'] ?? 'yangi',
                    date: _formatDate(d['createdAt']),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = (ts as Timestamp).toDate();
      return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

// ─── Order Row ────────────────────────────────────────────────────────────────

class _OrderRow extends StatelessWidget {
  final String orderId;
  final String name;
  final double total;
  final String currency;
  final String status;
  final String date;

  const _OrderRow({
    required this.orderId,
    required this.name,
    required this.total,
    required this.currency,
    required this.status,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Text(
            '#$orderId',
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF555555))),
          ),
          Text(date,
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFF888888))),
          const SizedBox(width: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            currency == 'KRW'
                ? '₩${_fmt(total.toInt())}'
                : "${_fmt(total.toInt())} so'm",
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1A5C52)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'tasdiqlandi' => const Color(0xFF34C759),
        'yetkazildi' => const Color(0xFF5B8DEF),
        'bekor' => Colors.red,
        'yangi' => const Color(0xFFB8963E),
        _ => const Color(0xFFB8963E),
      };

  String _statusLabel(String status) => switch (status) {
        'tasdiqlandi' => 'Tasdiqlandi',
        'yetkazildi' => 'Yetkazildi',
        'bekor' => 'Bekor',
        'yangi' => 'Yangi',
        _ => 'Kutilmoqda',
      };

  String _fmt(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ─── Products List ────────────────────────────────────────────────────────────

class _ProductsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              'Mahsulotlar',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A)),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .limit(6)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF1A5C52))),
                );
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text("Mahsulotlar yo'q",
                        style: TextStyle(color: Color(0xFF888888))),
                  ),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final cat = d['category'] as String? ?? '';
                  final catColor = _categoryColor(cat);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(color: Colors.grey.shade100)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            d['imageUrl'] ?? '',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 44,
                              height: 44,
                              color: const Color(0xFFE8F3F1),
                              child: const Icon(Icons.image_outlined,
                                  color: Color(0xFF1A5C52), size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d['name'] ?? '',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A1A1A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: catColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                      fontSize: 10, color: catColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₩${_fmt((d['priceKrw'] as num? ?? 0).toInt())}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF1A5C52)),
                            ),
                            Text(
                              "${_fmt((d['priceUzs'] as num? ?? 0).toInt())} so'm",
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF888888)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Color _categoryColor(String cat) {
    if (cat == 'Kosmetika') return const Color(0xFFD4899A);
    if (cat == 'Vitaminlar') return const Color(0xFF5B8DEF);
    return const Color(0xFF34C759);
  }

  String _fmt(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

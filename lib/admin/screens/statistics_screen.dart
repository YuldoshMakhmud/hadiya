import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistika',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 4),
            const Text(
              "Buyurtmalar va mahsulotlar bo'yicha statistika",
              style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .snapshots(),
                builder: (context, snap) {
                  final orders = snap.data?.docs ?? [];
                  int yangi = 0, tasdiqlandi = 0, yetkazildi = 0, bekor = 0;
                  double totalKrw = 0, totalUzs = 0;

                  for (final o in orders) {
                    final d = o.data() as Map<String, dynamic>;
                    final status = d['status'] as String? ?? 'yangi';
                    final price = (d['finalPrice'] as num? ?? 0).toDouble();
                    final currency = d['currency'] as String? ?? 'UZS';

                    switch (status) {
                      case 'yangi':
                        yangi++;
                        break;
                      case 'tasdiqlandi':
                        tasdiqlandi++;
                        if (currency == 'KRW') {
                          totalKrw += price;
                        } else {
                          totalUzs += price;
                        }
                        break;
                      case 'yetkazildi':
                        yetkazildi++;
                        if (currency == 'KRW') {
                          totalKrw += price;
                        } else {
                          totalUzs += price;
                        }
                        break;
                      case 'bekor':
                        bekor++;
                        break;
                    }
                  }

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // Status stats
                        _SectionTitle(title: 'Buyurtmalar holati'),
                        const SizedBox(height: 16),
                        _StatusGrid(
                          yangi: yangi,
                          tasdiqlandi: tasdiqlandi,
                          yetkazildi: yetkazildi,
                          bekor: bekor,
                          total: orders.length,
                        ),
                        const SizedBox(height: 28),

                        // Revenue
                        _SectionTitle(title: 'Daromad'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _RevenueCard(
                                label: 'Won (₩)',
                                value: '₩${_fmt(totalKrw.toInt())}',
                                icon: Icons.monetization_on_outlined,
                                color: const Color(0xFF1A5C52),
                                bg: const Color(0xFFE8F3F1),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _RevenueCard(
                                label: "So'm",
                                value: "${_fmt(totalUzs.toInt())} so'm",
                                icon: Icons.monetization_on_outlined,
                                color: const Color(0xFFB8963E),
                                bg: const Color(0xFFFFF8EC),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Category stats
                        _SectionTitle(title: 'Mahsulot kategoriyalari'),
                        const SizedBox(height: 16),
                        _CategoryStats(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int price) {
    if (price == 0) return '0';
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A)),
      ),
    );
  }
}

class _StatusGrid extends StatelessWidget {
  final int yangi, tasdiqlandi, yetkazildi, bekor, total;

  const _StatusGrid({
    required this.yangi,
    required this.tasdiqlandi,
    required this.yetkazildi,
    required this.bekor,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatusItem('Yangi', yangi, total, const Color(0xFFB8963E),
          Icons.fiber_new_outlined),
      _StatusItem('Tasdiqlandi', tasdiqlandi, total,
          const Color(0xFF34C759), Icons.check_circle_outline),
      _StatusItem('Yetkazildi', yetkazildi, total,
          const Color(0xFF5B8DEF), Icons.local_shipping_outlined),
      _StatusItem(
          'Bekor', bekor, total, Colors.red, Icons.cancel_outlined),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.8,
      children: items
          .map((item) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border(
                    left: BorderSide(color: item.color, width: 4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: item.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${item.count}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: item.color,
                            ),
                          ),
                          Text(
                            item.label,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF888888)),
                          ),
                          if (item.total > 0)
                            Text(
                              '${(item.count / item.total * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: item.color,
                                  fontWeight: FontWeight.w500),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _StatusItem {
  final String label;
  final int count;
  final int total;
  final Color color;
  final IconData icon;
  const _StatusItem(
      this.label, this.count, this.total, this.color, this.icon);
}

class _RevenueCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  const _RevenueCard({
    required this.label,
    required this.value,
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
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFF888888))),
        ],
      ),
    );
  }
}

class _CategoryStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        int kosmetika = 0, vitaminlar = 0, ginseng = 0;

        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          final cat = data['category'] as String? ?? '';
          if (cat == 'Kosmetika') kosmetika++;
          if (cat == 'Vitaminlar') vitaminlar++;
          if (cat == 'Ginseng') ginseng++;
        }

        final total = docs.length;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _CatRow('Kosmetika', kosmetika, total,
                  const Color(0xFFD4899A), '💄'),
              const SizedBox(height: 12),
              _CatRow('Vitaminlar', vitaminlar, total,
                  const Color(0xFF5B8DEF), '💊'),
              const SizedBox(height: 12),
              _CatRow(
                  'Ginseng', ginseng, total, const Color(0xFF34C759), '🌿'),
            ],
          ),
        );
      },
    );
  }
}

class _CatRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final String emoji;

  const _CatRow(this.label, this.count, this.total, this.color, this.emoji);

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$count ta',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

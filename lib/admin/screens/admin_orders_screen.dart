import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _filterStatus = 'Barchasi';

  static const _primary = Color(0xFF1A5C52);

  final _statuses = [
    'Barchasi',
    'yangi',
    'tasdiqlandi',
    'yetkazildi',
    'bekor',
  ];

  final _statusLabels = {
    'Barchasi': 'Barchasi',
    'yangi': 'Yangi',
    'tasdiqlandi': 'Tasdiqlandi',
    'yetkazildi': 'Yetkazildi',
    'bekor': 'Bekor',
  };

  final _statusColors = {
    'yangi': Color(0xFFB8963E),
    'tasdiqlandi': Color(0xFF34C759),
    'yetkazildi': Color(0xFF5B8DEF),
    'bekor': Colors.red,
  };

  Future<void> _updateStatus(String docId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(docId)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      body: Padding(
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
                    Text('Buyurtmalar',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A))),
                    SizedBox(height: 4),
                    Text('Barcha buyurtmalarni boshqarish',
                        style: TextStyle(
                            fontSize: 14, color: Color(0xFF888888))),
                  ],
                ),
                const Spacer(),
                // New orders indicator
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('status', isEqualTo: 'yangi')
                      .snapshots(),
                  builder: (context, snap) {
                    final count = snap.data?.docs.length ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8EC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFB8963E).withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFB8963E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "$count ta yangi buyurtma",
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFB8963E),
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Status filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statuses.map((s) {
                  final isActive = _filterStatus == s;
                  final color = s == 'Barchasi'
                      ? _primary
                      : (_statusColors[s] ?? _primary);
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _filterStatus = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? color : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? color
                              : const Color(0xFFEEEEEE),
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        _statusLabels[s] ?? s,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF555555),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Orders list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: _primary));
                  }

                  var docs = snap.data?.docs ?? [];
                  if (_filterStatus != 'Barchasi') {
                    docs = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return (data['status'] ?? 'yangi') ==
                          _filterStatus;
                    }).toList();
                  }

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 56,
                              color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text("Buyurtmalar yo'q",
                              style:
                                  TextStyle(color: Color(0xFF888888))),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final doc = docs[i];
                      final d = doc.data() as Map<String, dynamic>;
                      return _OrderCard(
                        docId: doc.id,
                        data: d,
                        statusColors: _statusColors,
                        statusLabels: _statusLabels,
                        onStatusChange: (s) =>
                            _updateStatus(doc.id, s),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final Map<String, Color> statusColors;
  final Map<String, String> statusLabels;
  final ValueChanged<String> onStatusChange;

  const _OrderCard({
    required this.docId,
    required this.data,
    required this.statusColors,
    required this.statusLabels,
    required this.onStatusChange,
  });

  static const _primary = Color(0xFF1A5C52);

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'yangi';
    final statusColor = statusColors[status] ?? const Color(0xFFB8963E);
    final items = data['items'] as List<dynamic>? ?? [];
    final isNew = status == 'yangi';
    final currency = data['currency'] as String? ?? 'UZS';
    final price = (data['finalPrice'] as num? ?? 0).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isNew
            ? Border.all(
                color: const Color(0xFFB8963E).withOpacity(0.4),
                width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // New order banner
          if (isNew)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8EC),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fiber_new_outlined,
                      size: 16, color: Color(0xFFB8963E)),
                  const SizedBox(width: 8),
                  const Text(
                    'Yangi buyurtma',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB8963E)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFB8963E).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("YANGI",
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB8963E))),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F3F1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${docId.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['userName'] ?? 'Mehmon',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF1A1A1A)),
                          ),
                          if (data['userPhone'] != null &&
                              (data['userPhone'] as String).isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined,
                                    size: 12,
                                    color: Color(0xFF888888)),
                                const SizedBox(width: 2),
                                Text(
                                  data['userPhone'],
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF888888)),
                                ),
                              ],
                            ),
                          if (data['telegramUsername'] != null &&
                              (data['telegramUsername'] as String)
                                  .isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.telegram,
                                    size: 12,
                                    color: Color(0xFF229ED9)),
                                const SizedBox(width: 2),
                                Text(
                                  '@${data['telegramUsername']}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF229ED9)),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // Status dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withOpacity(0.3)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: status,
                          isDense: true,
                          style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w600),
                          icon: Icon(Icons.keyboard_arrow_down,
                              size: 16, color: statusColor),
                          items: [
                            'yangi',
                            'tasdiqlandi',
                            'yetkazildi',
                            'bekor',
                          ]
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                        statusLabels[s] ?? s,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF1A1A1A))),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) onStatusChange(v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // Items
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 10),
                  ...items.take(3).map((item) {
                    final i = item as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          if ((i['imageUrl'] ?? '').isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                i['imageUrl'],
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 36,
                                  height: 36,
                                  color: const Color(0xFFE8F3F1),
                                  child: const Icon(
                                      Icons.image_outlined,
                                      size: 16,
                                      color: _primary),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F3F1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 16,
                                  color: _primary),
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              i['name'] ?? '',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A1A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'x${i['qty'] ?? 1}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF888888)),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (items.length > 3)
                    Text(
                      '+${items.length - 3} ta boshqa mahsulot',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFAAAAAA)),
                    ),
                ],

                // Quick action buttons for new orders
                if (isNew) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          label: "Tasdiqlash",
                          icon: Icons.check_circle_outline,
                          bgColor: const Color(0xFF34C759),
                          textColor: Colors.white,
                          onTap: () => _confirmAction(
                            context,
                            title: "Buyurtmani tasdiqlash",
                            content: "Buyurtma tasdiqlansinmi?",
                            confirmLabel: "Tasdiqlash",
                            confirmColor: const Color(0xFF34C759),
                            onConfirm: () =>
                                onStatusChange('tasdiqlandi'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionBtn(
                          label: "Bekor qilish",
                          icon: Icons.cancel_outlined,
                          bgColor: Colors.red.shade50,
                          textColor: Colors.red.shade600,
                          borderColor: Colors.red.shade200,
                          onTap: () => _confirmAction(
                            context,
                            title: "Buyurtmani bekor qilish",
                            content: "Buyurtma bekor qilinsinmi?",
                            confirmLabel: "Bekor qilish",
                            confirmColor: Colors.red,
                            onConfirm: () => onStatusChange('bekor'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 10),

                // Footer
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(data['createdAt']),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF888888)),
                    ),
                    const Spacer(),
                    const Text(
                      'Jami: ',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF888888)),
                    ),
                    Text(
                      currency == 'KRW'
                          ? '₩${_fmt(price.toInt())}'
                          : "${_fmt(price.toInt())} so'm",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _primary),
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

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Bekor",
                style: TextStyle(color: Color(0xFF888888))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = (ts as Timestamp).toDate();
      return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
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

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: borderColor != null
              ? Border.all(color: borderColor!)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

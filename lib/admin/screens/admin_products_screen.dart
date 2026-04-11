import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_edit_product_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  String _search = '';
  String _selectedCategory = 'Barchasi';

  static const _primary = Color(0xFF1A5C52);

  Future<void> _deleteProduct(String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("O'chirish"),
        content: Text('"$name" ni o\'chirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Bekor",
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("O'chirish",
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(docId)
          .delete();
    }
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
                    Text('Mahsulotlar',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A))),
                    SizedBox(height: 4),
                    Text('Barcha mahsulotlarni boshqarish',
                        style: TextStyle(
                            fontSize: 14, color: Color(0xFF888888))),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddEditProductScreen()),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Mahsulot qo'shish"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search + Category filter
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: const InputDecoration(
                        hintText: 'Mahsulot qidiring...',
                        hintStyle: TextStyle(
                            color: Color(0xFFAAAAAA), fontSize: 14),
                        prefixIcon: Icon(Icons.search,
                            color: Color(0xFF1A5C52), size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('categories')
                      .where('active', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snap) {
                    final catDocs = snap.data?.docs ?? [];
                    final categories = [
                      'Barchasi',
                      ...catDocs.map((d) =>
                          (d.data() as Map<String, dynamic>)['name']
                              as String? ??
                          ''),
                    ];
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((cat) {
                          final isActive = _selectedCategory == cat;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 9),
                              decoration: BoxDecoration(
                                color:
                                    isActive ? _primary : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isActive
                                      ? _primary
                                      : const Color(0xFFDDDDDD),
                                ),
                              ),
                              child: Text(
                                cat,
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
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table
            Expanded(
              child: Container(
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
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF1A5C52)));
                    }

                    var docs = snap.data?.docs ?? [];

                    if (_selectedCategory != 'Barchasi') {
                      docs = docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return (data['category'] as String? ?? '') ==
                            _selectedCategory;
                      }).toList();
                    }

                    if (_search.isNotEmpty) {
                      docs = docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return (data['name'] as String? ?? '')
                            .toLowerCase()
                            .contains(_search.toLowerCase());
                      }).toList();
                    }

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 56,
                                color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text("Mahsulotlar yo'q",
                                style:
                                    TextStyle(color: Color(0xFF888888))),
                            const SizedBox(height: 8),
                            const Text(
                                "\"Mahsulot qo'shish\" tugmasini bosing",
                                style: TextStyle(
                                    color: Color(0xFFAAAAAA),
                                    fontSize: 12)),
                          ],
                        ),
                      );
                    }

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        children: [
                          // Table header
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            color: const Color(0xFFF0F7F5),
                            child: const Row(
                              children: [
                                SizedBox(width: 56),
                                Expanded(
                                    flex: 3,
                                    child: Text('Nomi',
                                        style: _headerStyle)),
                                Expanded(
                                    flex: 2,
                                    child: Text('Kategoriya',
                                        style: _headerStyle)),
                                Expanded(
                                    flex: 2,
                                    child: Text('Narx (₩ / so\'m)',
                                        style: _headerStyle)),
                                SizedBox(
                                    width: 80,
                                    child: Text('Amallar',
                                        style: _headerStyle,
                                        textAlign: TextAlign.center)),
                              ],
                            ),
                          ),
                          // Table rows
                          Expanded(
                            child: ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (_, i) {
                                final doc = docs[i];
                                final d =
                                    doc.data() as Map<String, dynamic>;
                                return _ProductRow(
                                  docId: doc.id,
                                  data: d,
                                  onDelete: () => _deleteProduct(
                                      doc.id, d['name'] ?? ''),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

const _headerStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: Color(0xFF888888),
  letterSpacing: 0.5,
);

class _ProductRow extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onDelete;

  const _ProductRow({
    required this.docId,
    required this.data,
    required this.onDelete,
  });

  static const _primary = Color(0xFF1A5C52);

  @override
  Widget build(BuildContext context) {
    final cat = data['category'] as String? ?? '';
    final catColor = _catColor(cat);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              data['imageUrl'] ?? '',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 44,
                height: 44,
                color: const Color(0xFFE8F3F1),
                child: const Icon(Icons.image_outlined,
                    color: _primary, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + badges
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? '',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    if (data['isBestSeller'] == true)
                      _Badge('Best', const Color(0xFFB8963E)),
                    if (data['isNew'] == true)
                      _Badge('Yangi', _primary),
                  ],
                ),
              ],
            ),
          ),

          // Category
          Expanded(
            flex: 2,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat,
                style: TextStyle(
                    fontSize: 12, color: catColor),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Price
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₩${_fmt((data['priceKrw'] as num? ?? 0).toInt())}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1A1A1A)),
                ),
                Text(
                  "${_fmt((data['priceUzs'] as num? ?? 0).toInt())} so'm",
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),

          // Actions
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: Color(0xFF5B8DEF)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditProductScreen(
                        docId: docId,
                        existing: data,
                      ),
                    ),
                  ),
                  tooltip: 'Tahrirlash',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: Colors.red.shade400),
                  onPressed: onDelete,
                  tooltip: "O'chirish",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _catColor(String cat) {
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

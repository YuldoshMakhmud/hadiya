import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/products_provider.dart';
import '../../providers/app_provider.dart';
import 'web_product_detail_screen.dart';
import 'web_cart_screen.dart';

class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  static const _primary = Color(0xFF1A5C52);

  @override
  Widget build(BuildContext context) {
    final productsProvider = context.watch<ProductsProvider>();
    final appProvider = context.watch<AppProvider>();
    final products = productsProvider.products;
    final isWon = appProvider.isWon;
    final cartCount = appProvider.cartCount;
    final selectedCat = productsProvider.selectedCategory;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A5C52), Color(0xFF2A7A6E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
                child: Row(
                  children: [
                    // Logo
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.spa,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hadiya',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Koreya kosmetikasi',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Currency toggle
                    GestureDetector(
                      onTap: () => appProvider.toggleCurrency(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isWon ? '₩' : "so'm",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.swap_horiz,
                                color: Colors.white70, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.white,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('categories')
                      .where('active', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snap) {
                    final docs = snap.data?.docs ?? [];
                    final cats = [
                      {'name': 'Barchasi', 'emoji': '🛍'},
                      ...docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return {
                          'name': data['name'] ?? '',
                          'emoji': data['emoji'] ?? '',
                          'imageUrl': data['imageUrl'] ?? '',
                          'order': data['order'] ?? 0,
                        };
                      }).toList()
                        ..sort((a, b) =>
                            (a['order'] as int).compareTo(b['order'] as int)),
                    ];
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: cats.map((cat) {
                          final name = cat['name'] as String;
                          final emoji = cat['emoji'] as String;
                          final imageUrl = cat['imageUrl'] as String? ?? '';
                          final isActive = selectedCat == name;
                          return GestureDetector(
                            onTap: () => productsProvider.setCategory(name),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? _primary
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (imageUrl.isNotEmpty && name != 'Barchasi')
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        imageUrl,
                                        width: 18,
                                        height: 18,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Text(emoji,
                                                style: const TextStyle(
                                                    fontSize: 14)),
                                      ),
                                    )
                                  else
                                    Text(emoji,
                                        style:
                                            const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 5),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isActive
                                          ? Colors.white
                                          : const Color(0xFF555555),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ── Products grid ─────────────────────────────────────────────
          if (productsProvider.loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF1A5C52)),
              ),
            )
          else if (products.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text("Mahsulotlar yo'q",
                        style: TextStyle(color: Color(0xFF888888))),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final p = products[i];
                    return _ProductCard(
                      product: p,
                      isWon: isWon,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WebProductDetailScreen(
                            product: p,
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: products.length,
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
              ),
            ),

          // Bottom spacing
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),

      // ── Cart FAB ──────────────────────────────────────────────────────
      floatingActionButton: cartCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WebCartScreen()),
              ),
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart_outlined),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2E4CF),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A5C52)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              label: Text('Savat  ${appProvider.cartTotalFormatted}'),
            )
          : null,
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }

}

// ─── Product Card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isWon;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.isWon,
    required this.onTap,
  });

  static const _primary = Color(0xFF1A5C52);

  @override
  Widget build(BuildContext context) {
    final name = product['name'] as String? ?? '';
    final imageUrl = product['imageUrl'] as String? ?? '';
    final priceKrw = (product['priceKrw'] as num? ?? 0).toDouble();
    final priceUzs = (product['priceUzs'] as num? ?? 0).toDouble();
    final isBestSeller = product['isBestSeller'] == true;
    final isNew = product['isNew'] == true;

    final priceText = isWon
        ? '₩${_fmt(priceKrw.toInt())}'
        : "${_fmt(priceUzs.toInt())} so'm";

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFE8F3F1),
                        child: const Center(
                          child: Icon(Icons.image_outlined,
                              color: _primary, size: 32),
                        ),
                      ),
                    ),
                  ),
                  if (isBestSeller)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB8963E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Best',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (isNew)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Yangi',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceText,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

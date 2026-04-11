import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/product.dart' show Product;

class WebProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const WebProductDetailScreen({super.key, required this.product});

  @override
  State<WebProductDetailScreen> createState() =>
      _WebProductDetailScreenState();
}

class _WebProductDetailScreenState
    extends State<WebProductDetailScreen> {
  static const _primary = Color(0xFF1A5C52);

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isWon = appProvider.isWon;

    final name = widget.product['name'] as String? ?? '';
    final description = widget.product['description'] as String? ?? '';
    final imageUrl = widget.product['imageUrl'] as String? ?? '';
    final priceKrw =
        (widget.product['priceKrw'] as num? ?? 0).toDouble();
    final priceUzs =
        (widget.product['priceUzs'] as num? ?? 0).toDouble();
    final cat = widget.product['category'] as String? ?? '';
    final isBestSeller = widget.product['isBestSeller'] == true;
    final isNew = widget.product['isNew'] == true;

    // Build Product for cart
    final product = Product(
      id: widget.product['id'] as String? ?? '',
      name: name,
      description: description,
      priceKrw: priceKrw,
      priceUzs: priceUzs,
      category: cat,
      imageUrl: imageUrl,
      isBestSeller: isBestSeller,
      isNew: isNew,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            AspectRatio(
              aspectRatio: 1.2,
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFE8F3F1),
                      child: const Center(
                        child: Icon(Icons.image_outlined,
                            color: _primary, size: 48),
                      ),
                    ),
                  ),
                  // Badges
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: [
                        if (isBestSeller)
                          _Badge(
                              'Best Seller', const Color(0xFFB8963E)),
                        if (isBestSeller && isNew)
                          const SizedBox(width: 6),
                        if (isNew) _Badge('Yangi', _primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _catColor(cat).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_catEmoji(cat)} $cat',
                      style: TextStyle(
                          fontSize: 12,
                          color: _catColor(cat),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F8F5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (!isWon) appProvider.toggleCurrency();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              decoration: BoxDecoration(
                                color: isWon
                                    ? _primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '₩${_fmt(priceKrw.toInt())}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isWon
                                          ? Colors.white
                                          : const Color(0xFF888888),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    '🇰🇷 Korean Won',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isWon
                                          ? Colors.white70
                                          : const Color(0xFFAAAAAA),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (isWon) appProvider.toggleCurrency();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              decoration: BoxDecoration(
                                color: !isWon
                                    ? _primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "${_fmt(priceUzs.toInt())} so'm",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: !isWon
                                          ? Colors.white
                                          : const Color(0xFF888888),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    "🇺🇿 O'zbek so'mi",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: !isWon
                                          ? Colors.white70
                                          : const Color(0xFFAAAAAA),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Tavsif',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF555555),
                        height: 1.6),
                  ),
                  const SizedBox(height: 32),

                  // Add to cart button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<AppProvider>().addToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Savatga qo'shildi"),
                            backgroundColor: _primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text(
                        "Savatga qo'shish",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _catColor(String cat) {
    if (cat == 'Kosmetika') return const Color(0xFFD4899A);
    if (cat == 'Vitaminlar') return const Color(0xFF5B8DEF);
    return const Color(0xFF34C759);
  }

  String _catEmoji(String cat) {
    switch (cat) {
      case 'Kosmetika':
        return '💄';
      case 'Vitaminlar':
        return '💊';
      default:
        return '🌿';
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

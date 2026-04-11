import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/product.dart';
import '../providers/app_provider.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isInWishlist = provider.isInWishlist(product.id);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Rasm + ustma-ust elementlar ───────────────────────────
            Stack(
              children: [
                // Rasm
                Container(
                  height: 148,
                  width: double.infinity,
                  color: AppColors.cream.withOpacity(0.3),
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.cream.withOpacity(0.3),
                      child: const Icon(Icons.image_not_supported,
                          color: AppColors.primary, size: 40),
                    ),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      );
                    },
                  ),
                ),

                // Pastdan gradient (rating va button ko'rinishi uchun)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Yuqori chap: BEST / YANGI badge
                if (product.isBestSeller || product.isNew)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: product.isBestSeller
                            ? AppColors.primary
                            : Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.isBestSeller ? 'BEST' : 'YANGI',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Yuqori o'ng: ❤ Wishlist tugmasi
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => provider.toggleWishlist(product),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: Icon(
                        isInWishlist ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: isInWishlist ? Colors.red : AppColors.grey,
                      ),
                    ),
                  ),
                ),

                // Past chap: ⭐ Reyting
                Positioned(
                  bottom: 7,
                  left: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        '${product.rating}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '(${product.reviewCount})',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                // Past o'ng: ➕ Savatga qo'shish tugmasi
                Positioned(
                  bottom: 6,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      provider.addToCart(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Savatga qo\'shildi ✓'),
                          duration: Duration(seconds: 1),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add,
                          size: 18, color: AppColors.cream),
                    ),
                  ),
                ),
              ],
            ),

            // ── Matn qismi: faqat nom + narx ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2A2A2A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.getPrice(provider.isWon),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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
}

class Product {
  final String id;
  final String name;
  final String description;
  final double priceKrw;
  final double priceUzs;
  final String category;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final bool isNew;
  final bool isBestSeller;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.priceKrw,
    required this.priceUzs,
    required this.category,
    required this.imageUrl,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.isNew = false,
    this.isBestSeller = false,
  });

  String getPrice(bool isWon) {
    if (isWon) {
      return '₩${priceKrw.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    } else {
      return "${(priceUzs / 1000).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ming so'm";
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';
import '../models/product.dart' show Product;
import '../providers/app_provider.dart';
import '../widgets/hadiya_logo.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildMainPage(provider),
          _buildWishlistPage(provider),
          const CartScreen(embedded: true),
          const OrdersScreen(embedded: true),
          _buildProfilePage(provider),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(provider),
    );
  }

  Widget _buildBottomNav(AppProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Bosh sahifa',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Sevimlilar',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_bag_outlined),
                if (provider.cartCount > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${provider.cartCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: const Icon(Icons.shopping_bag),
            label: 'Savat',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Buyurtmalar',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildMainPage(AppProvider provider) {
    final products = provider.filteredProducts;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 100,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.primary,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SearchScreen()),
                    ),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(Icons.search,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Mahsulot qidirish...',
                            style: TextStyle(
                                color: AppColors.primary.withOpacity(0.5),
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _CurrencyToggle(),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildBanner(provider)),
        SliverToBoxAdapter(child: _buildCategories(provider)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mahsulotlar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '${products.length} ta',
                  style: const TextStyle(color: AppColors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        products.isEmpty
            ? const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      'Mahsulot topilmadi',
                      style: TextStyle(color: AppColors.grey),
                    ),
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(product: product),
                          ),
                        ),
                      );
                    },
                    childCount: products.length,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildBanner(AppProvider provider) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('banners')
          .where('active', isEqualTo: true)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];

        // Firestore'da banner yo'q bo'lsa — default banner
        if (docs.isEmpty) {
          return _defaultBanner(provider);
        }

        // Firestore'dan bannerlar — gorizontal scroll
        return SizedBox(
          height: 170,
          child: PageView.builder(
            itemCount: docs.length,
            controller: PageController(viewportFraction: 0.92),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final imageUrl = d['imageUrl'] as String? ?? '';
              final title = d['title'] as String? ?? '';
              final subtitle = d['subtitle'] as String? ?? '';
              final bgColor = d['bgColor'] as String? ?? '';

              Color color = AppColors.primary;
              if (bgColor.isNotEmpty) {
                try {
                  color = Color(int.parse(bgColor.replaceAll('#', '0xFF')));
                } catch (_) {}
              }

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 4, 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _bannerContent(title, subtitle, color),
                            ),
                            // Gradient overlay matn uchun
                            if (title.isNotEmpty)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(20)),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.65),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : _bannerContent(title, subtitle, color),
              );
            },
          ),
        );
      },
    );
  }

  Widget _bannerContent(String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.cream,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.cream.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.eco, color: AppColors.cream, size: 52),
        ],
      ),
    );
  }

  Widget _defaultBanner(AppProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      height: 170,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '✨ Koreya sifatli mahsulotlar',
                    style: TextStyle(
                      color: AppColors.cream,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kosmetika · Vitaminlar · Ginseng',
                    style: TextStyle(
                      color: AppColors.cream.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.cream.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      provider.locationLabel,
                      style:
                          const TextStyle(color: AppColors.cream, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.eco, color: AppColors.cream, size: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories(AppProvider provider) {
    return SizedBox(
      height: 90,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('categories')
            .where('active', isEqualTo: true)
            .snapshots(),
        builder: (context, snap) {
          final catDocs = snap.data?.docs ?? [];
          final firestoreCats = catDocs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return {
              'label': data['name'] as String? ?? '',
              'emoji': data['emoji'] as String? ?? '📦',
              'imageUrl': data['imageUrl'] as String? ?? '',
              'order': data['order'] as int? ?? 0,
              'value': data['name'] as String?,
            };
          }).toList()
            ..sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

          final categories = <Map<String, dynamic>>[
            {'label': 'Barchasi', 'emoji': '🛍', 'imageUrl': '', 'value': null},
            ...firestoreCats,
          ];

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final cat = categories[i];
              final isSelected = provider.selectedCategory == cat['value'];
              final imageUrl = cat['imageUrl'] as String? ?? '';
              final emoji = cat['emoji'] as String? ?? '📦';

              return GestureDetector(
                onTap: () => provider.setCategory(cat['value'] as String?),
                child: Container(
                  margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (imageUrl.isNotEmpty && cat['value'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Text(emoji,
                                style: const TextStyle(fontSize: 20)),
                          ),
                        )
                      else
                        Text(emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(
                        cat['label'] as String,
                        style: TextStyle(
                          color:
                              isSelected ? AppColors.cream : AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWishlistPage(AppProvider provider) {
    final wishlist = provider.wishlist;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Sevimlilar'), automaticallyImplyLeading: false),
      body: wishlist.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_outline,
                      size: 64, color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Sevimli mahsulotlar yo\'q',
                    style: TextStyle(color: AppColors.grey, fontSize: 15),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: wishlist.length,
              itemBuilder: (context, i) => ProductCard(
                product: wishlist[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: wishlist[i]),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePage(AppProvider provider) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Profil'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Avatar & info ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              color: AppColors.primary,
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.cream,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        provider.userName.isNotEmpty
                            ? provider.userName[0].toUpperCase()
                            : 'H',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider.userName,
                    style: const TextStyle(
                      color: AppColors.cream,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.userEmail,
                    style: TextStyle(
                      color: AppColors.cream.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cream.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${provider.locationLabel}  ·  ${provider.currencyLabel}',
                      style:
                          const TextStyle(color: AppColors.cream, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Asosiy ───────────────────────────────────────────────
            _SectionLabel("Asosiy"),
            _ProfileTile(
              icon: Icons.location_on_outlined,
              title: 'Mamlakatni o\'zgartirish',
              subtitle: provider.locationLabel,
              onTap: () => Navigator.pushNamed(context, '/country'),
            ),
            _ProfileTile(
              icon: Icons.currency_exchange,
              title: 'Valyutani o\'zgartirish',
              subtitle: provider.currencyLabel,
              onTap: () => provider.toggleCurrency(),
            ),
            _ProfileTile(
              icon: Icons.shopping_bag_outlined,
              title: 'Savat',
              subtitle: '${provider.cartCount} ta mahsulot',
              onTap: () => setState(() => _currentIndex = 2),
            ),
            _ProfileTile(
              icon: Icons.receipt_long_outlined,
              title: 'Buyurtmalarim',
              subtitle: 'Buyurtmalar tarixi',
              onTap: () => setState(() => _currentIndex = 3),
            ),
            _ProfileTile(
              icon: Icons.favorite_outline,
              title: 'Sevimlilar',
              subtitle: '${provider.wishlist.length} ta mahsulot',
              onTap: () => setState(() => _currentIndex = 1),
            ),

            const SizedBox(height: 8),

            // ── Qo'llab-quvvatlash ────────────────────────────────────
            _SectionLabel("Qo'llab-quvvatlash"),
            _ProfileTile(
              icon: Icons.send_outlined,
              title: 'Telegram',
              subtitle: 'Bizga yozing',
              iconColor: const Color(0xFF229ED9),
              onTap: () => _launch(dotenv.env['SUPPORT_TELEGRAM'] ?? ''),
            ),
            _ProfileTile(
              icon: Icons.phone_outlined,
              title: 'Telefon',
              subtitle: dotenv.env['SUPPORT_PHONE'] ?? '',
              iconColor: const Color(0xFF34C759),
              onTap: () => _launch('tel:${dotenv.env['SUPPORT_PHONE'] ?? ''}'),
            ),
            _ProfileTile(
              icon: Icons.camera_alt_outlined,
              title: 'Instagram',
              subtitle: '@hadiya_shop',
              iconColor: const Color(0xFFE1306C),
              onTap: () => _launch(dotenv.env['SUPPORT_INSTAGRAM'] ?? ''),
            ),
            _ProfileTile(
              icon: Icons.music_note_outlined,
              title: 'TikTok',
              subtitle: '@hadiya_shop',
              iconColor: const Color(0xFF010101),
              onTap: () => _launch(dotenv.env['SUPPORT_TIKTOK'] ?? ''),
            ),

            const SizedBox(height: 8),

            // ── Huquqiy ───────────────────────────────────────────────
            _SectionLabel("Ma'lumot"),
            _ProfileTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Maxfiylik siyosati',
              subtitle: 'Privacy Policy',
              onTap: () => _launch(dotenv.env['PRIVACY_POLICY_URL'] ?? ''),
            ),

            const SizedBox(height: 16),

            // ── Chiqish ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  provider.logout().then((_) {
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/country');
                    }
                  });
                },
                icon: const Icon(Icons.logout),
                label: const Text('Chiqish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

class _CurrencyToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return GestureDetector(
      onTap: () => provider.toggleCurrency(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              provider.isWon ? '₩' : "so'm",
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.swap_horiz, color: AppColors.primary, size: 14),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.grey.withOpacity(0.7),
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          )
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Color(0xFF333333))),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppColors.grey, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 14, color: AppColors.grey),
        onTap: onTap,
      ),
    );
  }
}

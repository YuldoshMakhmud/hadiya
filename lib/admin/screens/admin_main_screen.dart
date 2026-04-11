import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';
import 'admin_products_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_banners_screen.dart';
import 'admin_categories_screen.dart';
import 'statistics_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  static const _primary = Color(0xFF1A5C52);
  static const _cream = Color(0xFFF2E4CF);
  static const _sidebarBg = Color(0xFF1A2E2A);

  final List<_NavItem> _navItems = const [
    _NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    _NavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'Mahsulotlar',
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'Buyurtmalar',
      badgeStream: true,
    ),
    _NavItem(
      icon: Icons.image_outlined,
      activeIcon: Icons.image,
      label: 'Bannerlar',
    ),
    _NavItem(
      icon: Icons.category_outlined,
      activeIcon: Icons.category,
      label: 'Kategoriyalar',
    ),
    _NavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      label: 'Statistika',
    ),
  ];

  final List<Widget> _screens = const [
    DashboardScreen(),
    AdminProductsScreen(),
    AdminOrdersScreen(),
    AdminBannersScreen(),
    AdminCategoriesScreen(),
    StatisticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isWide ? 240 : 72,
            child: _Sidebar(
              selectedIndex: _selectedIndex,
              navItems: _navItems,
              isWide: isWide,
              user: user,
              onTap: (i) => setState(() => _selectedIndex = i),
              primary: _primary,
              cream: _cream,
              sidebarBg: _sidebarBg,
            ),
          ),

          // Main content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nav Item Model ───────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool badgeStream;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeStream = false,
  });
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> navItems;
  final bool isWide;
  final User? user;
  final ValueChanged<int> onTap;
  final Color primary;
  final Color cream;
  final Color sidebarBg;

  const _Sidebar({
    required this.selectedIndex,
    required this.navItems,
    required this.isWide,
    required this.user,
    required this.onTap,
    required this.primary,
    required this.cream,
    required this.sidebarBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: sidebarBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo area
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A5C52), Color(0xFF2A7A6E)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.spa, color: Colors.white, size: 20),
                ),
                if (isWide) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hadiya',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                              color: Color(0xFF88A89E), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: navItems.length,
              itemBuilder: (_, i) {
                final item = navItems[i];
                final isActive = selectedIndex == i;

                return GestureDetector(
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 14 : 0,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? primary.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isActive
                          ? Border.all(
                              color: primary.withOpacity(0.4))
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: isWide
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        item.badgeStream
                            ? _OrdersBadgeIcon(
                                icon: isActive
                                    ? item.activeIcon
                                    : item.icon,
                                isActive: isActive,
                                primary: primary,
                              )
                            : Icon(
                                isActive ? item.activeIcon : item.icon,
                                color: isActive
                                    ? cream
                                    : const Color(0xFF88A89E),
                                size: 22,
                              ),
                        if (isWide) ...[
                          const SizedBox(width: 12),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: isActive
                                  ? cream
                                  : const Color(0xFF88A89E),
                              fontSize: 14,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          if (item.badgeStream) ...[
                            const Spacer(),
                            _OrdersCountBadge(),
                          ],
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // User info + logout
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF243B36),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person,
                      color: Color(0xFF1A5C52), size: 18),
                ),
                if (isWide) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user?.displayName ?? 'Admin',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                              color: Color(0xFF88A89E), fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout,
                        color: Color(0xFF88A89E), size: 18),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    tooltip: 'Chiqish',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ] else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Orders badge icon ────────────────────────────────────────────────────────

class _OrdersBadgeIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color primary;

  const _OrdersBadgeIcon(
      {required this.icon, required this.isActive, required this.primary});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _pendingCount(),
      builder: (context, snap) {
        final count = snap.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              color: isActive
                  ? const Color(0xFFF2E4CF)
                  : const Color(0xFF88A89E),
              size: 22,
            ),
            if (count > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Orders count badge ───────────────────────────────────────────────────────

class _OrdersCountBadge extends StatelessWidget {
  const _OrdersCountBadge();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _pendingCount(),
      builder: (context, snap) {
        final count = snap.data ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFF3B30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}

Stream<int> _pendingCount() {
  try {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'yangi')
        .snapshots()
        .map((s) => s.docs.length);
  } catch (_) {
    return Stream.value(0);
  }
}

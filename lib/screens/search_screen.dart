import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../providers/app_provider.dart';
import '../models/product.dart' show Product;
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  String _query = '';
  List<String> _recent = [];

  static const _prefsKey = 'recent_searches';
  static const _maxRecent = 8;

  @override
  void initState() {
    super.initState();
    _loadRecent();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _recent = prefs.getStringList(_prefsKey) ?? [];
      });
    }
  }

  Future<void> _saveRecent(String q) async {
    if (q.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _recent.remove(q);
    _recent.insert(0, q);
    if (_recent.length > _maxRecent) _recent = _recent.sublist(0, _maxRecent);
    await prefs.setStringList(_prefsKey, _recent);
    if (mounted) setState(() {});
  }

  Future<void> _removeRecent(String q) async {
    final prefs = await SharedPreferences.getInstance();
    _recent.remove(q);
    await prefs.setStringList(_prefsKey, _recent);
    if (mounted) setState(() {});
  }

  Future<void> _clearAllRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    if (mounted) setState(() => _recent.clear());
  }

  void _search(String q) {
    final trimmed = q.trim();
    setState(() => _query = trimmed);
    _ctrl.text = trimmed;
    _ctrl.selection =
        TextSelection.fromPosition(TextPosition(offset: trimmed.length));
    if (trimmed.isNotEmpty) _saveRecent(trimmed);
  }

  List<Product> _filterResults(List<Product> all) {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return all.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final results = _filterResults(provider.allProductsList);
    final isLoading = provider.productsLoading;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
              ),
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    onChanged: (v) => setState(() => _query = v.trim()),
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) _saveRecent(v.trim());
                    },
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Mahsulot qidirish...',
                      hintStyle: TextStyle(
                          color: AppColors.primary.withOpacity(0.45),
                          fontSize: 14),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.primary, size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close,
                                  color: AppColors.primary, size: 18),
                              onPressed: () {
                                _ctrl.clear();
                                setState(() => _query = '');
                              },
                              padding: EdgeInsets.zero,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _query.isEmpty
          ? _buildRecentPage()
          : _buildResultsPage(results, isLoading),
    );
  }

  // ── Recent searches ─────────────────────────────────────────────────────────

  Widget _buildRecentPage() {
    if (_recent.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('Qidirish uchun yozing',
                style: TextStyle(color: AppColors.grey, fontSize: 15)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 12, 8),
          child: Row(
            children: [
              const Text(
                'So\'nggi qidiruvlar',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.3),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearAllRecent,
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text(
                  'Barchasini o\'chirish',
                  style: TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _recent.length,
            separatorBuilder: (_, __) => const Divider(
                height: 1, indent: 52, color: Color(0xFFEEEEEE)),
            itemBuilder: (_, i) {
              final q = _recent[i];
              return ListTile(
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history,
                      color: AppColors.primary, size: 16),
                ),
                title: Text(q,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF333333))),
                trailing: IconButton(
                  icon: const Icon(Icons.close,
                      size: 16, color: AppColors.grey),
                  onPressed: () => _removeRecent(q),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                onTap: () => _search(q),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Results ─────────────────────────────────────────────────────────────────

  Widget _buildResultsPage(List<Product> results, bool isLoading) {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('"$_query" topilmadi',
                style: const TextStyle(
                    color: AppColors.grey, fontSize: 15)),
            const SizedBox(height: 6),
            const Text(
              'Boshqa kalit so\'z bilan urining',
              style: TextStyle(color: AppColors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: Text(
            '${results.length} ta natija',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: results.length,
            itemBuilder: (_, i) => ProductCard(
              product: results[i],
              onTap: () {
                _saveRecent(_query);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProductDetailScreen(product: results[i]),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

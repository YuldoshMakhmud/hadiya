import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/app_provider.dart';
import '../../models/cart_item.dart';
import '../../services/telegram_service.dart';

class WebCartScreen extends StatefulWidget {
  const WebCartScreen({super.key});

  @override
  State<WebCartScreen> createState() => _WebCartScreenState();
}

class _WebCartScreenState extends State<WebCartScreen> {
  static const _primary = Color(0xFF1A5C52);

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _ordered = false;
  String? _orderId;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    // capture before async gap
    final appProvider = context.read<AppProvider>();
    final isWon = appProvider.isWon;
    final cart = List.of(appProvider.cart);
    final total = appProvider.cartTotal;
    final currency = isWon ? 'KRW' : 'UZS';
    final userName = _nameCtrl.text.trim();
    final userPhone = _phoneCtrl.text.trim();

    setState(() => _loading = true);

    try {
      final items = cart.map((item) => {
            'name': item.product.name,
            'imageUrl': item.product.imageUrl,
            'priceKrw': item.product.priceKrw,
            'priceUzs': item.product.priceUzs,
            'qty': item.quantity,
          }).toList();

      final tgUser = TelegramService.user;

      final docRef =
          await FirebaseFirestore.instance.collection('orders').add({
        'items': items,
        'currency': currency,
        'finalPrice': total,
        'userName': userName,
        'userPhone': userPhone,
        'telegramUsername': tgUser['username'] ?? '',
        'telegramUserId': tgUser['id'] ?? '',
        'status': 'yangi',
        'source': 'telegram_miniapp',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear cart
      final ids = cart.map((i) => i.product.id).toList();
      for (final id in ids) {
        appProvider.removeFromCart(id);
      }

      if (!mounted) return;
      setState(() {
        _loading = false;
        _ordered = true;
        _orderId = docRef.id.substring(0, 8).toUpperCase();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Xatolik: $e"),
        backgroundColor: Colors.red.shade400,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ordered) return _OrderConfirmation(orderId: _orderId ?? '');

    final appProvider = context.watch<AppProvider>();
    final cart = appProvider.cart;
    final isWon = appProvider.isWon;

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
          'Savat (${cart.length} ta)',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    "Savat bo'sh",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF888888)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Mahsulotlarni savatga qo'shing",
                    style: TextStyle(
                        fontSize: 14, color: Color(0xFFAAAAAA)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Xaridga qaytish"),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cart items
                    ...cart.map((item) {
                      return _CartItemTile(
                        item: item,
                        isWon: isWon,
                        onRemove: () =>
                            appProvider.removeFromCart(item.product.id),
                        onIncrease: () => appProvider
                            .updateCartQuantity(
                                item.product.id, item.quantity + 1),
                        onDecrease: () => appProvider
                            .updateCartQuantity(
                                item.product.id, item.quantity - 1),
                      );
                    }),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Jami:',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A)),
                        ),
                        Text(
                          appProvider.cartTotalFormatted,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // User info form
                    const Text(
                      "Buyurtmachi ma'lumotlari",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 12),

                    // Pre-fill from Telegram
                    Builder(builder: (ctx) {
                      final tgName = TelegramService.fullName;
                      if (tgName.isNotEmpty &&
                          _nameCtrl.text.isEmpty) {
                        _nameCtrl.text = tgName;
                      }
                      return const SizedBox.shrink();
                    }),

                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _inputDec(
                          'Ismingiz', Icons.person_outlined),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Ism kiriting'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDec(
                          'Telefon raqamingiz',
                          Icons.phone_outlined),
                      validator: (v) =>
                          v == null || v.length < 7
                              ? 'Telefon kiriting'
                              : null,
                    ),
                    const SizedBox(height: 28),

                    // Order button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed:
                            _loading ? null : () => _placeOrder(context),
                        icon: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: const Text(
                          'Buyurtma berish',
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
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        "Buyurtma berish bilan siz biz bilan bog'lanishga rozilik bildirasiz",
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDec(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
        prefixIcon: Icon(icon, color: _primary, size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F8F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E8E6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
        ),
      );
}

// ─── Cart Item Tile ───────────────────────────────────────────────────────────

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final bool isWon;
  final VoidCallback onRemove;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  static const _primary = Color(0xFF1A5C52);

  const _CartItemTile({
    required this.item,
    required this.isWon,
    required this.onRemove,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    final price = isWon ? item.product.priceKrw : item.product.priceUzs;
    final totalPrice = price * item.quantity;
    final priceText = isWon
        ? '₩${_fmt(totalPrice.toInt())}'
        : "${_fmt(totalPrice.toInt())} so'm";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              item.product.imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: const Color(0xFFE8F3F1),
                child: const Icon(Icons.image_outlined,
                    color: _primary, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                      fontSize: 14,
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
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.red),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onDecrease,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFE0E8E6)),
                      ),
                      child: const Icon(Icons.remove,
                          size: 14, color: Color(0xFF888888)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  GestureDetector(
                    onTap: onIncrease,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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

// ─── Order Confirmation ───────────────────────────────────────────────────────

class _OrderConfirmation extends StatelessWidget {
  final String orderId;

  const _OrderConfirmation({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3F1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: Color(0xFF1A5C52), size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Buyurtma qabul qilindi!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2E4CF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Buyurtma #$orderId',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A5C52)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Tez orada siz bilan bog'lanamiz.\nXaridingiz uchun rahmat!",
                style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF555555),
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Close mini app or go back to home
                    int count = 0;
                    Navigator.of(context).popUntil((_) => count++ >= 2);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A5C52),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Bosh sahifaga qaytish',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

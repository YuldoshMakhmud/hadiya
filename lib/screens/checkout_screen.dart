import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../app_theme.dart';
import '../models/cart_item.dart';
import '../providers/app_provider.dart';
import '../providers/orders_provider.dart';
import '../services/hadiya_bot_service.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;
  final double total;

  const CheckoutScreen({
    super.key,
    required this.items,
    required this.total,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  Uint8List? _receiptBytes;
  String _receiptExt = 'jpg';
  bool _uploading = false;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    // Foydalanuvchi ismini avvaldan to'ldirish
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AppProvider>();
      if (p.userName.isNotEmpty) _nameCtrl.text = p.userName;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  // ── Chek rasmini tanlash ─────────────────────────────────────────
  Future<void> _pickReceipt() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Chek rasmini tanlash',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.primary),
                ),
                title: const Text('Kamera',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Rasm olish'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.primary),
                ),
                title: const Text('Galereya',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Galereyadan tanlash'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;
    try {
      final xFile = await ImagePicker()
          .pickImage(source: source, imageQuality: 75);
      if (xFile == null || !mounted) return;
      final bytes = await xFile.readAsBytes();
      final ext = xFile.path.split('.').last.toLowerCase();
      if (!mounted) return;
      setState(() {
        _receiptBytes = bytes;
        _receiptExt = ext.isEmpty ? 'jpg' : ext;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Rasm tanlashda xato: $e', isError: true);
    }
  }

  // ── Firebase Storage yuklash ─────────────────────────────────────
  Future<String?> _uploadReceipt(String orderId) async {
    if (_receiptBytes == null) return null;
    setState(() => _uploading = true);
    try {
      final ref = FirebaseStorage.instance.ref(
          'hadiya/receipts/$orderId/chek_${DateTime.now().millisecondsSinceEpoch}.$_receiptExt');
      final metadata = SettableMetadata(
          contentType: 'image/$_receiptExt');
      await ref.putData(_receiptBytes!, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Chek yuklash xato: $e');
      return null;
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ── Buyurtmani tasdiqlash ────────────────────────────────────────
  Future<void> _placeOrder() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack('Iltimos, ismingizni kiriting', isError: true);
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      _showSnack('Iltimos, telefon raqamni kiriting', isError: true);
      return;
    }
    if (_addressCtrl.text.trim().isEmpty) {
      _showSnack('Iltimos, manzilni kiriting', isError: true);
      return;
    }

    setState(() => _placing = true);

    final provider = context.read<AppProvider>();
    final ordersProvider = context.read<OrdersProvider>();
    final isWon = provider.isWon;
    final currency = isWon ? 'KRW' : 'UZS';

    // Mahsulotlar ro'yxati
    final itemsList = widget.items.map((ci) {
      final price = isWon ? ci.product.priceKrw : ci.product.priceUzs;
      final priceStr = isWon
          ? '₩${price.toStringAsFixed(0)}'
          : '${(price / 1000).toStringAsFixed(0)} ming so\'m';
      return {
        'productId': ci.product.id,
        'name': ci.product.name,
        'quantity': ci.quantity,
        'price': priceStr,
        'priceRaw': price * ci.quantity,
      };
    }).toList();

    // Vaqtinchalik ID (chek yuklaish uchun)
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    String? receiptUrl;
    if (_receiptBytes != null) {
      receiptUrl = await _uploadReceipt(tempId);
    }

    if (!mounted) return;

    // Firestore ga saqlash
    final orderId = await ordersProvider.createOrder(
      items: itemsList,
      currency: currency,
      total: widget.total,
      userName: _nameCtrl.text.trim(),
      userEmail: provider.userEmail,
      contact: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      comment: _commentCtrl.text.trim(),
      receiptUrl: receiptUrl,
    );

    if (!mounted) return;

    if (orderId == null) {
      setState(() => _placing = false);
      _showSnack(ordersProvider.error ?? 'Buyurtma berishda xato', isError: true);
      return;
    }

    // Telegram ga yuborish (background)
    HadiyaBotService.sendOrder(
      orderId: orderId,
      userName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      items: itemsList,
      total: widget.total,
      currency: currency,
      comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      receiptImageUrl: receiptUrl,
    );

    // Savatni tozalash
    provider.clearCart();

    setState(() => _placing = false);

    if (!mounted) return;

    // SnackBar uchun messenger'ni pop'dan OLDIN olamiz
    final messenger = ScaffoldMessenger.of(context);
    final shortId = orderId.substring(0, 6).toUpperCase();

    // Checkout sahifasini yop
    Navigator.of(context).pop();

    // Savat sahifasida muvaffaqiyat xabarini ko'rsat
    messenger.showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '✅ Buyurtma #$shortId qabul qilindi!',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ]),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isWon = provider.isWon;
    final busy = _placing || _uploading;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.cream,
        elevation: 0,
        title: const Text(
          'Buyurtma berish',
          style: TextStyle(
              color: AppColors.cream,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Buyurtma tarkibi ───────────────────────────
                  _section('🛍️ Buyurtma tarkibi'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8)
                      ],
                    ),
                    child: Column(
                      children: widget.items.map((ci) {
                        final price = isWon
                            ? ci.product.priceKrw
                            : ci.product.priceUzs;
                        final itemTotal = price * ci.quantity;
                        final priceStr = isWon
                            ? '₩${itemTotal.toStringAsFixed(0)}'
                            : '${(itemTotal / 1000).toStringAsFixed(0)} ming so\'m';

                        return Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                ci.product.imageUrl,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 52,
                                  height: 52,
                                  color: AppColors.cream.withOpacity(0.3),
                                  child: const Icon(Icons.image_not_supported,
                                      color: AppColors.primary, size: 22),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ci.product.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${ci.quantity} dona',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              priceStr,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ]),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Ism ───────────────────────────────────────
                  _section('👤 Ism'),
                  const SizedBox(height: 8),
                  _input(
                    controller: _nameCtrl,
                    hint: 'To\'liq ismingiz',
                    icon: Icons.person_outline,
                  ),

                  const SizedBox(height: 16),

                  // ── Telefon ────────────────────────────────────
                  _section('📞 Telefon'),
                  const SizedBox(height: 8),
                  _input(
                    controller: _phoneCtrl,
                    hint: '+998 90 123 45 67',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 16),

                  // ── Manzil ─────────────────────────────────────
                  _section('📍 Yetkazish manzili'),
                  const SizedBox(height: 8),
                  _input(
                    controller: _addressCtrl,
                    hint: 'Shahar, ko\'cha, uy raqami...',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 16),

                  // ── Izoh ──────────────────────────────────────
                  _section('💬 Izoh (ixtiyoriy)'),
                  const SizedBox(height: 8),
                  _input(
                    controller: _commentCtrl,
                    hint: 'Qo\'shimcha xabar...',
                    icon: Icons.edit_note_outlined,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 20),

                  // ── To'lov rekvizitlari ────────────────────────
                  _section('💳 To\'lov rekvizitlari'),
                  const SizedBox(height: 10),
                  _buildBankCard(),

                  const SizedBox(height: 20),

                  // ── Chek rasmi ─────────────────────────────────
                  _section('🧾 To\'lov cheki (ixtiyoriy)'),
                  const SizedBox(height: 4),
                  Text(
                    'To\'lovdan so\'ng skrinshot yuboring',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  _buildReceiptPicker(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Bottom: jami + tasdiqlash ─────────────────────────
          _buildBottom(isWon: isWon, busy: busy),
        ],
      ),
    );
  }

  // ── Bank rekvizitlari ────────────────────────────────────────────
  Widget _buildBankCard() {
    final bankName = dotenv.env['BANK_NAME'] ?? '';
    final account = dotenv.env['BANK_ACCOUNT'] ?? '';
    final owner = dotenv.env['BANK_OWNER'] ?? '';
    final currency = dotenv.env['BANK_CURRENCY'] ?? 'UZS';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                bankName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currency,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Karta raqami
          Row(
            children: [
              Expanded(
                child: Text(
                  account,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(
                      text: account.replaceAll(' ', '')));
                  _showSnack('Karta raqami nusxalandi ✓');
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.copy,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  color: Colors.white60, size: 15),
              const SizedBox(width: 6),
              Text(
                owner,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white70, size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'To\'lovdan so\'ng chek rasmini yuboring',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Chek yuklash widget ──────────────────────────────────────────
  Widget _buildReceiptPicker() {
    return GestureDetector(
      onTap: _placing ? null : _pickReceipt,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 110),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _receiptBytes != null
                ? AppColors.primary
                : Colors.grey.shade300,
            width: _receiptBytes != null ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ],
        ),
        child: _receiptBytes != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.memory(
                      _receiptBytes!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // X — o'chirish
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _receiptBytes = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  // Chek tanlandi badge
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.white, size: 13),
                          SizedBox(width: 5),
                          Text(
                            'Chek tanlandi',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // O'zgartirish
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _pickReceipt,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text('O\'zgartirish',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : SizedBox(
                height: 110,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 28,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chek rasmini yuklash',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kamera yoki galereya',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 11),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Bottom bar ───────────────────────────────────────────────────
  Widget _buildBottom({required bool isWon, required bool busy}) {
    final totalStr = isWon
        ? '₩${widget.total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'
        : '${(widget.total / 1000).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ming so\'m';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Jami summa:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                  totalStr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: busy ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: busy
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _uploading
                                ? 'Chek yuklanmoqda...'
                                : 'Buyurtma berilmoqda...',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Buyurtmani tasdiqlash',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon:
              Icon(icon, color: AppColors.primary.withOpacity(0.6), size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

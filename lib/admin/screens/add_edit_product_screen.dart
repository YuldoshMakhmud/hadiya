import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AddEditProductScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existing;

  const AddEditProductScreen({super.key, this.docId, this.existing});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _uploading = false;
  double _uploadProgress = 0;

  static const _primary = Color(0xFF1A5C52);
  static const _krwToUzs = 15.0;
  List<String> _categories = [];

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceKrwCtrl;
  late final TextEditingController _priceUzsCtrl;
  String _category = '';
  bool _isBestSeller = false;
  bool _isNew = false;

  String? _imageUrl;       // Firestore'dagi mavjud URL
  XFile? _pickedFile;      // Yangi tanlangan fayl
  Uint8List? _pickedBytes; // Web uchun bytes

  bool get _isEdit => widget.docId != null;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    _nameCtrl = TextEditingController(text: d?['name'] ?? '');
    _descCtrl = TextEditingController(text: d?['description'] ?? '');
    _priceKrwCtrl = TextEditingController(
        text: d != null ? '${(d['priceKrw'] as num? ?? 0).toInt()}' : '');
    _priceUzsCtrl = TextEditingController(
        text: d != null ? '${(d['priceUzs'] as num? ?? 0).toInt()}' : '');
    _imageUrl = d?['imageUrl'];
    _category = d?['category'] ?? '';
    _isBestSeller = d?['isBestSeller'] ?? false;
    _isNew = d?['isNew'] ?? false;

    _priceKrwCtrl.addListener(_autoCalcUzs);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('categories')
          .where('active', isEqualTo: true)
          .get();
      final cats = snap.docs
          .map((d) => (d.data()['name'] as String? ?? ''))
          .where((n) => n.isNotEmpty)
          .toList();
      if (mounted) {
        setState(() {
          _categories = cats;
          if (_category.isEmpty && cats.isNotEmpty) {
            _category = cats.first;
          }
        });
      }
    } catch (_) {}
  }

  void _autoCalcUzs() {
    if (_priceUzsCtrl.text.isEmpty) {
      final krw = double.tryParse(_priceKrwCtrl.text);
      if (krw != null) {
        _priceUzsCtrl.text = (krw * _krwToUzs).toInt().toString();
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceKrwCtrl.dispose();
    _priceUzsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedFile = file;
      _pickedBytes = bytes;
    });
  }

  Future<String?> _uploadImage() async {
    if (_pickedFile == null) return _imageUrl;
    setState(() {
      _uploading = true;
      _uploadProgress = 0;
    });
    try {
      final ext = _pickedFile!.name.split('.').last.toLowerCase();
      final path =
          'hadiya/products/product_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref = FirebaseStorage.instance.ref().child(path);

      late UploadTask task;
      if (kIsWeb) {
        task = ref.putData(
            _pickedBytes!,
            SettableMetadata(contentType: 'image/$ext'));
      } else {
        task = ref.putFile(File(_pickedFile!.path));
      }

      task.snapshotEvents.listen((s) {
        if (s.totalBytes > 0) {
          setState(() =>
              _uploadProgress = s.bytesTransferred / s.totalBytes);
        }
      });

      await task;
      return await ref.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Rasm yuklashda xato: $e'),
          backgroundColor: Colors.red.shade400,
        ));
      }
      return _imageUrl;
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final uploadedUrl = await _uploadImage();

      final priceKrw = double.tryParse(_priceKrwCtrl.text.trim()) ?? 0;
      final priceUzs = double.tryParse(_priceUzsCtrl.text.trim()) ??
          (priceKrw * _krwToUzs);

      final docData = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'priceKrw': priceKrw,
        'priceUzs': priceUzs,
        'category': _category,
        'imageUrl': uploadedUrl ?? '',
        'isBestSeller': _isBestSeller,
        'isNew': _isNew,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEdit) {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.docId)
            .update(docData);
      } else {
        docData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('products').add(docData);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Xatolik: $e'),
          backgroundColor: Colors.red.shade400,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? 'Mahsulotni tahrirlash' : "Mahsulot qo'shish",
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: (_loading || _uploading) ? null : _save,
              icon: (_loading || _uploading)
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_outlined, size: 16),
              label: Text(_isEdit ? 'Saqlash' : "Qo'shish"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Rasm ─────────────────────────────────────────────
                  _Section(
                    title: 'Mahsulot rasmi',
                    subtitle: 'Galereyadan rasm tanlang',
                    children: [
                      GestureDetector(
                        onTap: _uploading ? null : _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 220,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F3F1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: _primary.withOpacity(0.3),
                                width: 1.5),
                          ),
                          child: _buildImageArea(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Asosiy ma'lumotlar ────────────────────────────────
                  _Section(
                    title: "Asosiy ma'lumotlar",
                    children: [
                      _field(_nameCtrl, 'Mahsulot nomi',
                          Icons.label_outline,
                          validator: (v) =>
                              v!.isEmpty ? 'Nom kiriting' : null),
                      const SizedBox(height: 14),
                      _field(_descCtrl, 'Tavsif',
                          Icons.description_outlined,
                          maxLines: 3),
                      const SizedBox(height: 14),
                      if (_categories.isEmpty)
                        _loadingBox()
                      else
                        DropdownButtonFormField<String>(
                          value: _categories.contains(_category)
                              ? _category
                              : _categories.first,
                          onChanged: (v) =>
                              setState(() => _category = v!),
                          decoration: _inputDec(
                              'Kategoriya', Icons.category_outlined),
                          items: _categories
                              .map((e) => DropdownMenuItem(
                                  value: e, child: Text(e)))
                              .toList(),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Narxlar ───────────────────────────────────────────
                  _Section(
                    title: 'Narxlar',
                    subtitle:
                        "KRW kiriting — UZS avtomatik hisoblanadi (1 ₩ = 15 so'm)",
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              _priceKrwCtrl,
                              'Narx (₩ Won)',
                              Icons.monetization_on_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  v!.isEmpty ? 'Narx kiriting' : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _field(
                              _priceUzsCtrl,
                              "Narx (so'm)",
                              Icons.monetization_on_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "UZS bo'sh qoldirilsa, KRW dan avtomatik hisoblanadi",
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFFAAAAAA)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Belgilar ──────────────────────────────────────────
                  _Section(
                    title: 'Belgilar',
                    children: [
                      SwitchListTile(
                        title: const Text('Best Seller'),
                        subtitle: const Text(
                            'Mahsulot bestsellar sifatida belgilanadi'),
                        value: _isBestSeller,
                        activeColor: _primary,
                        onChanged: (v) =>
                            setState(() => _isBestSeller = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        title: const Text('Yangi mahsulot'),
                        subtitle:
                            const Text('"Yangi" belgisi ko\'rsatiladi'),
                        value: _isNew,
                        activeColor: _primary,
                        onChanged: (v) => setState(() => _isNew = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    // Upload jarayonida progress
    if (_uploading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 180,
            child: LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.white.withOpacity(0.4),
              valueColor: const AlwaysStoppedAnimation(_primary),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${(_uploadProgress * 100).toInt()}% yuklandi...',
            style: const TextStyle(
                color: _primary, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    // Yangi tanlangan rasm (bytes bilan)
    if (_pickedBytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.memory(_pickedBytes!, fit: BoxFit.cover),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: _changeBtn(),
          ),
        ],
      );
    }

    // Mavjud URL dan rasm
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.network(
              _imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _uploadHint(),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: _changeBtn(),
          ),
        ],
      );
    }

    // Bo'sh holat
    return _uploadHint();
  }

  Widget _uploadHint() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_photo_alternate_outlined,
              color: _primary, size: 32),
        ),
        const SizedBox(height: 10),
        const Text('Rasm yuklash',
            style: TextStyle(
                color: _primary,
                fontWeight: FontWeight.w600,
                fontSize: 15)),
        const SizedBox(height: 4),
        Text('Galereyadan tanlang',
            style:
                TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ],
    );
  }

  Widget _changeBtn() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text("O'zgartirish",
              style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _loadingBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFF1A5C52)),
          ),
          SizedBox(width: 10),
          Text('Kategoriyalar yuklanmoqda...',
              style:
                  TextStyle(color: Color(0xFFAAAAAA), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (_) => setState(() {}),
      decoration: _inputDec(label, icon),
    );
  }

  InputDecoration _inputDec(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: Color(0xFFAAAAAA), fontSize: 14),
        prefixIcon: Icon(icon, color: _primary, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
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
          borderSide:
              BorderSide(color: Colors.red.shade300, width: 1.5),
        ),
      );
}

// ─── Section ──────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const _Section(
      {required this.title, this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A))),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF888888))),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

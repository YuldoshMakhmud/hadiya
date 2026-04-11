import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AdminBannersScreen extends StatelessWidget {
  const AdminBannersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bannerlar',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A))),
                    SizedBox(height: 4),
                    Text('Home page bannerlari',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF888888))),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showBannerDialog(context, null, null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Yangi banner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A5C52),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('banners')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF1A5C52)));
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F3F1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.image_outlined,
                                size: 48, color: Color(0xFF1A5C52)),
                          ),
                          const SizedBox(height: 16),
                          const Text('Bannerlar yo\'q',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A))),
                          const SizedBox(height: 6),
                          const Text(
                              'Yangi banner qo\'shish uchun + tugmasini bosing',
                              style: TextStyle(
                                  color: Color(0xFF888888), fontSize: 13)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final d = doc.data() as Map<String, dynamic>;
                      return _BannerCard(
                        docId: doc.id,
                        data: d,
                        onEdit: () =>
                            _showBannerDialog(context, doc.id, d),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBannerDialog(BuildContext context, String? docId,
      Map<String, dynamic>? existing) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BannerDialog(docId: docId, existing: existing),
    );
  }
}

// ── Banner Card ───────────────────────────────────────────────────────────────

class _BannerCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;

  const _BannerCard(
      {required this.docId, required this.data, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '';
    final subtitle = data['subtitle'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String? ?? '';
    final bgColor = data['bgColor'] as String? ?? '#1A5C52';
    final active = data['active'] as bool? ?? true;

    Color color = const Color(0xFF1A5C52);
    try {
      color = Color(int.parse(bgColor.replaceAll('#', '0xFF')));
    } catch (_) {}

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          // Preview rasm
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl,
                    width: 120,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _colorBox(color, title))
                : _colorBox(color, title),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title.isNotEmpty ? title : 'Nomsiz',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1A1A1A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Switch(
                      value: active,
                      activeColor: const Color(0xFF1A5C52),
                      onChanged: (val) => FirebaseFirestore.instance
                          .collection('banners')
                          .doc(docId)
                          .update({'active': val}),
                    ),
                  ],
                ),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFF888888), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.grey.shade300))),
                    const SizedBox(width: 4),
                    Text(bgColor,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF888888))),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFEFFAF1)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        active ? 'Faol' : 'Nofaol',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? const Color(0xFF34C759)
                                : const Color(0xFF888888)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 20, color: Color(0xFF1A5C52)),
                    onPressed: onEdit,
                    tooltip: 'Tahrirlash'),
                IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.red),
                    onPressed: () => _confirmDelete(context),
                    tooltip: 'O\'chirish'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorBox(Color color, String title) {
    return Container(
      width: 120,
      height: 88,
      color: color,
      child: Center(
        child: Text(
          title.isNotEmpty ? title[0].toUpperCase() : 'H',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Bannerni o\'chirish'),
        content:
            const Text('Bu bannerni o\'chirishni tasdiqlaysizmi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bekor')),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('banners')
                  .doc(docId)
                  .delete();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('O\'chirish',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Banner Dialog ─────────────────────────────────────────────────────────────

class _BannerDialog extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existing;
  const _BannerDialog({this.docId, this.existing});

  @override
  State<_BannerDialog> createState() => _BannerDialogState();
}

class _BannerDialogState extends State<_BannerDialog> {
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _bgColorCtrl = TextEditingController(text: '#1A5C52');

  bool _active = true;
  bool _saving = false;

  // Rasm
  XFile? _pickedFile;       // web uchun XFile
  File? _pickedFileIo;      // mobile uchun File
  String _existingImageUrl = '';
  double _uploadProgress = 0;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e['title'] ?? '';
      _subtitleCtrl.text = e['subtitle'] ?? '';
      _bgColorCtrl.text = e['bgColor'] ?? '#1A5C52';
      _active = e['active'] ?? true;
      _existingImageUrl = e['imageUrl'] ?? '';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _bgColorCtrl.dispose();
    super.dispose();
  }

  // ── Rasm tanlash ─────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xFile == null) return;

    setState(() {
      _pickedFile = xFile;
      if (!kIsWeb) _pickedFileIo = File(xFile.path);
    });
  }

  // ── Firebase Storage ga yuklash ──────────────────────────────────
  Future<String?> _uploadImage() async {
    if (_pickedFile == null) return _existingImageUrl;
    setState(() {
      _uploading = true;
      _uploadProgress = 0;
    });

    try {
      final ext = _pickedFile!.name.split('.').last.toLowerCase();
      final fileName =
          'banner_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref = FirebaseStorage.instance
          .ref('hadiya/banners/$fileName');

      UploadTask task;
      if (kIsWeb) {
        final bytes = await _pickedFile!.readAsBytes();
        task = ref.putData(bytes,
            SettableMetadata(contentType: 'image/$ext'));
      } else {
        task = ref.putFile(_pickedFileIo!);
      }

      // Progress kuzatish
      task.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          setState(() => _uploadProgress =
              event.bytesTransferred / event.totalBytes);
        }
      });

      await task;
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Banner rasm yuklash xato: $e');
      return _existingImageUrl;
    } finally {
      setState(() {
        _uploading = false;
        _uploadProgress = 0;
      });
    }
  }

  // ── Saqlash ──────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sarlavha kiritish majburiy'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _saving = true);

    // Avval rasmni yukla
    final imageUrl = await _uploadImage();

    final data = {
      'title': _titleCtrl.text.trim(),
      'subtitle': _subtitleCtrl.text.trim(),
      'imageUrl': imageUrl ?? '',
      'bgColor': _bgColorCtrl.text.trim().isEmpty
          ? '#1A5C52'
          : _bgColorCtrl.text.trim(),
      'active': _active,
    };

    try {
      if (widget.docId != null) {
        await FirebaseFirestore.instance
            .collection('banners')
            .doc(widget.docId)
            .update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('banners').add(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Preview widget ───────────────────────────────────────────────
  Widget _buildImagePreview() {
    // Yangi tanlangan rasm
    if (_pickedFile != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: kIsWeb
                ? Image.network(_pickedFile!.path,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover)
                : Image.file(_pickedFileIo!,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover),
          ),
          // O'zgartirish tugmasi
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('O\'zgartirish',
                        style:
                            TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          // O'chirish
          Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              onTap: () => setState(() {
                _pickedFile = null;
                _pickedFileIo = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      );
    }

    // Mavjud URL rasm
    if (_existingImageUrl.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _existingImageUrl,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _uploadPlaceholder(),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('O\'zgartirish',
                        style:
                            TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              onTap: () => setState(() => _existingImageUrl = ''),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      );
    }

    // Bo'sh — yuklash placeholder
    return _uploadPlaceholder();
  }

  Widget _uploadPlaceholder() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF1A5C52).withOpacity(0.3),
              style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_photo_alternate_outlined,
                  size: 32, color: Color(0xFF1A5C52)),
            ),
            const SizedBox(height: 10),
            const Text('Rasm yuklash',
                style: TextStyle(
                    color: Color(0xFF1A5C52),
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            const SizedBox(height: 3),
            const Text('Qurilmangizdan rasm tanlang',
                style:
                    TextStyle(color: Color(0xFF888888), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.docId != null;

    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3F1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.image_outlined,
                        color: Color(0xFF1A5C52), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Bannerni tahrirlash' : 'Yangi banner',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A)),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Rasm yuklash ──────────────────────────────────
              const Text('Banner rasmi',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444444))),
              const SizedBox(height: 8),
              _buildImagePreview(),

              // Upload progress
              if (_uploading) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: const Color(0xFFE8F3F1),
                    color: const Color(0xFF1A5C52),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Yuklanmoqda... ${(_uploadProgress * 100).toInt()}%',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF1A5C52)),
                ),
              ],

              const SizedBox(height: 16),

              // Sarlavha
              _field(
                controller: _titleCtrl,
                label: 'Sarlavha *',
                hint: 'Masalan: 20% chegirma!',
                icon: Icons.title,
              ),
              const SizedBox(height: 14),

              // Tavsif
              _field(
                controller: _subtitleCtrl,
                label: 'Tavsif (ixtiyoriy)',
                hint: 'Qo\'shimcha matn',
                icon: Icons.text_fields,
              ),
              const SizedBox(height: 14),

              // Fon rangi
              _field(
                controller: _bgColorCtrl,
                label: 'Fon rangi (rasm yo\'q bo\'lganda)',
                hint: '#1A5C52',
                icon: Icons.palette_outlined,
              ),
              const SizedBox(height: 14),

              // Active toggle
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_outlined,
                        size: 18, color: Color(0xFF555555)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Faol (home pageda ko\'rinadi)',
                          style: TextStyle(fontSize: 14)),
                    ),
                    Switch(
                      value: _active,
                      activeColor: const Color(0xFF1A5C52),
                      onChanged: (v) => setState(() => _active = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Saqlash
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_saving || _uploading) ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A5C52),
                    disabledBackgroundColor:
                        const Color(0xFF1A5C52).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: (_saving || _uploading)
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white)),
                            const SizedBox(width: 10),
                            Text(
                              _uploading
                                  ? 'Rasm yuklanmoqda...'
                                  : 'Saqlanmoqda...',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15),
                            ),
                          ],
                        )
                      : Text(
                          isEdit ? 'Saqlash' : 'Qo\'shish',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF444444))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: Color(0xFFAAAAAA), fontSize: 14),
            prefixIcon:
                Icon(icon, size: 18, color: const Color(0xFF888888)),
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF1A5C52)),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

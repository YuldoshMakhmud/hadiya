import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

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
                    Text('Kategoriyalar',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A))),
                    SizedBox(height: 4),
                    Text('Mahsulot kategoriyalarini boshqarish',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF888888))),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showCategoryDialog(context, null, null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Kategoriya qo'shish"),
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
                    .collection('categories')
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
                            child: const Icon(Icons.category_outlined,
                                size: 40, color: Color(0xFF1A5C52)),
                          ),
                          const SizedBox(height: 16),
                          const Text("Kategoriyalar yo'q",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A))),
                          const SizedBox(height: 6),
                          const Text("Yangi kategoriya qo'shing",
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFF888888))),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final data = doc.data() as Map<String, dynamic>;
                      final isActive = data['active'] == true;

                      return _CategoryCard(
                        doc: doc,
                        data: data,
                        isActive: isActive,
                        onEdit: () =>
                            _showCategoryDialog(context, doc.id, data),
                        onDelete: () =>
                            _deleteCategory(context, doc.id, data['name'] ?? ''),
                        onToggleActive: () => _toggleActive(doc.id, isActive),
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

  Future<void> _deleteCategory(
      BuildContext context, String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("O'chirish"),
        content: Text('"$name" kategoriyasini o\'chirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("O'chirish",
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(docId)
          .delete();
    }
  }

  Future<void> _toggleActive(String docId, bool current) async {
    await FirebaseFirestore.instance
        .collection('categories')
        .doc(docId)
        .update({'active': !current});
  }
}

// ─── Category Card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Map<String, dynamic> data;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _CategoryCard({
    required this.doc,
    required this.data,
    required this.isActive,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? '';
    final emoji = data['emoji'] as String? ?? '📦';
    final imageUrl = data['imageUrl'] as String? ?? '';
    final order = data['order'] as int? ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image / Emoji area
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _emojiPlaceholder(emoji),
                        )
                      : _emojiPlaceholder(emoji),
                ),
                // Active badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF1A5C52)
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? 'Aktiv' : 'Nofaol',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // Order badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#$order',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Toggle
                GestureDetector(
                  onTap: onToggleActive,
                  child: Icon(
                    isActive
                        ? Icons.toggle_on_rounded
                        : Icons.toggle_off_rounded,
                    color: isActive
                        ? const Color(0xFF1A5C52)
                        : Colors.grey.shade400,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 4),
                // Edit
                GestureDetector(
                  onTap: onEdit,
                  child: const Icon(Icons.edit_outlined,
                      size: 18, color: Color(0xFF1A5C52)),
                ),
                const SizedBox(width: 8),
                // Delete
                GestureDetector(
                  onTap: onDelete,
                  child:
                      Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emojiPlaceholder(String emoji) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFE8F3F1),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 40)),
      ),
    );
  }
}

// ─── Category Dialog ──────────────────────────────────────────────────────────

void _showCategoryDialog(
    BuildContext context, String? docId, Map<String, dynamic>? existing) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CategoryDialog(docId: docId, existing: existing),
  );
}

class _CategoryDialog extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existing;

  const _CategoryDialog({this.docId, this.existing});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _nameCtrl = TextEditingController();
  final _emojiCtrl = TextEditingController();
  final _orderCtrl = TextEditingController();

  bool _active = true;
  bool _saving = false;
  bool _uploading = false;
  double _uploadProgress = 0;

  String? _imageUrl;
  XFile? _pickedFile;
  Uint8List? _pickedBytes;

  static const _primary = Color(0xFF1A5C52);

  bool get _isEdit => widget.docId != null;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    if (d != null) {
      _nameCtrl.text = d['name'] ?? '';
      _emojiCtrl.text = d['emoji'] ?? '';
      _orderCtrl.text = '${d['order'] ?? 0}';
      _active = d['active'] ?? true;
      _imageUrl = d['imageUrl'];
    } else {
      _emojiCtrl.text = '📦';
      _orderCtrl.text = '0';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emojiCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
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
          'hadiya/categories/cat_${DateTime.now().millisecondsSinceEpoch}.$ext';
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
          setState(() => _uploadProgress = s.bytesTransferred / s.totalBytes);
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
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Kategoriya nomini kiriting'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final uploadedUrl = await _uploadImage();
      final data = {
        'name': _nameCtrl.text.trim(),
        'emoji': _emojiCtrl.text.trim().isEmpty ? '📦' : _emojiCtrl.text.trim(),
        'order': int.tryParse(_orderCtrl.text.trim()) ?? 0,
        'active': _active,
        'imageUrl': uploadedUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final col = FirebaseFirestore.instance.collection('categories');
      if (_isEdit) {
        await col.doc(widget.docId).update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await col.add(data);
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _pickedFile != null || (_imageUrl?.isNotEmpty == true);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Text(
                    _isEdit ? 'Kategoriyani tahrirlash' : "Kategoriya qo'shish",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A)),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Image upload
              GestureDetector(
                onTap: _uploading ? null : _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3F1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _primary.withOpacity(0.3), width: 1.5),
                  ),
                  child: _uploading
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 140,
                              child: LinearProgressIndicator(
                                value: _uploadProgress,
                                backgroundColor:
                                    Colors.white.withOpacity(0.4),
                                valueColor:
                                    const AlwaysStoppedAnimation(_primary),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(_uploadProgress * 100).toInt()}%',
                              style: const TextStyle(
                                  color: _primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : _pickedBytes != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: Image.memory(
                                    _pickedBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit,
                                            color: Colors.white, size: 12),
                                        SizedBox(width: 4),
                                        Text('O\'zgartirish',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : hasImage && _imageUrl != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(13),
                                      child: Image.network(
                                        _imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _uploadHint(),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.edit,
                                                color: Colors.white, size: 12),
                                            SizedBox(width: 4),
                                            Text('O\'zgartirish',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : _uploadHint(),
                ),
              ),
              const SizedBox(height: 20),

              // Name
              _field(_nameCtrl, 'Kategoriya nomi', Icons.label_outline,
                  hint: 'Masalan: Kosmetika'),
              const SizedBox(height: 14),

              // Emoji + Order in row
              Row(
                children: [
                  Expanded(
                    child: _field(
                        _emojiCtrl, 'Emoji', Icons.emoji_emotions_outlined,
                        hint: '💄'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                        _orderCtrl, 'Tartib raqami', Icons.sort,
                        hint: '1',
                        keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Active toggle
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDE8DD)),
                ),
                child: SwitchListTile(
                  title: const Text('Aktiv',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: const Text(
                      'Foydalanuvchi ilovada ko\'rinadi',
                      style: TextStyle(fontSize: 12)),
                  value: _active,
                  activeColor: _primary,
                  onChanged: (v) => setState(() => _active = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF888888),
                        side:
                            const BorderSide(color: Color(0xFFDDDDDD)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Bekor'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (_saving || _uploading) ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: (_saving || _uploading)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _isEdit ? 'Saqlash' : "Qo'shish",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _uploadHint() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child:
              const Icon(Icons.add_photo_alternate_outlined, color: _primary, size: 28),
        ),
        const SizedBox(height: 8),
        const Text('Rasm yuklash',
            style: TextStyle(
                color: _primary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 4),
        Text('Galereya',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
          borderSide: const BorderSide(color: Color(0xFFDDE8DD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
    );
  }
}

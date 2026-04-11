import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class HadiyaBotService {
  HadiyaBotService._();

  static String get _token => dotenv.env['TELEGRAM_BOT_TOKEN'] ?? '';
  static String get _chatId => dotenv.env['TELEGRAM_CHAT_ID'] ?? '';
  static String get _base => 'https://api.telegram.org/bot$_token';

  static bool get _ok =>
      _token.isNotEmpty &&
      _token != 'YOUR_BOT_TOKEN_HERE' &&
      _chatId.isNotEmpty &&
      _chatId != 'YOUR_CHAT_ID_HERE';

  /// Buyurtmani Telegram'ga yuboradi (chek bilan yoki cheksiz)
  static Future<void> sendOrder({
    required String orderId,
    required String userName,
    required String phone,
    required String address,
    required List<Map<String, dynamic>> items,
    required double total,
    required String currency,
    String? comment,
    String? receiptImagePath, // lokal fayl
    String? receiptImageUrl,  // Firebase URL
  }) async {
    if (!_ok) {
      debugPrint('HadiyaBotService: token yoki chatId sozlanmagan');
      return;
    }

    final text = _buildText(
      orderId: orderId,
      userName: userName,
      phone: phone,
      address: address,
      items: items,
      total: total,
      currency: currency,
      comment: comment,
    );

    try {
      if (receiptImagePath != null && receiptImagePath.isNotEmpty) {
        await _sendPhotoFile(filePath: receiptImagePath, caption: text);
      } else if (receiptImageUrl != null && receiptImageUrl.isNotEmpty) {
        await _sendPhotoUrl(url: receiptImageUrl, caption: text);
      } else {
        await _sendText(text);
      }
    } catch (e) {
      debugPrint('Telegram yuborishda xato: $e');
    }
  }

  static String _buildText({
    required String orderId,
    required String userName,
    required String phone,
    required String address,
    required List<Map<String, dynamic>> items,
    required double total,
    required String currency,
    String? comment,
  }) {
    final sb = StringBuffer();
    sb.writeln('🌿 *HADIYA — YANGI BUYURTMA*');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('🔖 ID: `#${orderId.substring(0, 8).toUpperCase()}`');
    sb.writeln('👤 Ism: *$userName*');
    sb.writeln('📞 Tel: `$phone`');
    sb.writeln('📍 Manzil: $address');
    if (comment != null && comment.isNotEmpty) {
      sb.writeln('💬 Izoh: $comment');
    }
    sb.writeln('💱 Valyuta: $currency');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('🧾 *Mahsulotlar:*');
    for (final item in items) {
      final name = item['name'] ?? '';
      final qty = item['quantity'] ?? 1;
      final price = item['price'] ?? '';
      sb.writeln('  • $name × $qty — $price');
    }
    sb.writeln('━━━━━━━━━━━━━━━━━━━━');

    // Valyutaga qarab formatlash
    String formatted;
    if (currency == 'KRW' || currency == '₩') {
      formatted =
          '₩${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    } else {
      formatted =
          "${(total / 1000).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ming so'm";
    }

    sb.writeln('💰 *Jami: $formatted*');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('📌 Status: ⏳ Yangi buyurtma');
    return sb.toString();
  }

  static Future<void> _sendText(String text) async {
    await http.post(
      Uri.parse('$_base/sendMessage'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'chat_id': _chatId,
        'text': text,
        'parse_mode': 'Markdown',
      }),
    );
  }

  static Future<void> _sendPhotoUrl({
    required String url,
    required String caption,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/sendPhoto'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'chat_id': _chatId,
        'photo': url,
        'caption': caption,
        'parse_mode': 'Markdown',
      }),
    );
    if (res.statusCode != 200) {
      await _sendText(caption);
    }
  }

  static Future<void> _sendPhotoFile({
    required String filePath,
    required String caption,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      await _sendText(caption);
      return;
    }
    final req = http.MultipartRequest('POST', Uri.parse('$_base/sendPhoto'));
    req.fields['chat_id'] = _chatId;
    req.fields['caption'] = caption;
    req.fields['parse_mode'] = 'Markdown';
    req.files.add(await http.MultipartFile.fromPath('photo', filePath));
    final res = await req.send();
    if (res.statusCode != 200) {
      await _sendText(caption);
    }
  }
}

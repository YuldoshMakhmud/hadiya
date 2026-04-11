// Conditional import: web'da dart:js ishlatiladi, mobileda stub
import 'telegram_service_stub.dart'
    if (dart.library.js) 'telegram_service_web.dart';

class TelegramService {
  TelegramService._();

  static bool get isAvailable => telegramIsAvailable();

  static void ready() => telegramReady();
  static void expand() => telegramExpand();
  static void close() => telegramClose();

  static Map<String, String> get user => telegramUser();

  static String get userId => user['id'] ?? '';

  static String get fullName {
    final u = user;
    if (u.isEmpty) return '';
    return '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim();
  }

  static String get username => user['username'] ?? '';

  static String get colorScheme => telegramColorScheme();
}

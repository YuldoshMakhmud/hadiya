// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:js' as js;

bool telegramIsAvailable() {
  try {
    if (!js.context.hasProperty('Telegram')) return false;
    final telegram = js.context['Telegram'];
    if (telegram == null) return false;
    return (telegram as js.JsObject).hasProperty('WebApp');
  } catch (_) {
    return false;
  }
}

js.JsObject? _webApp() {
  try {
    if (!telegramIsAvailable()) return null;
    return js.context['Telegram']['WebApp'] as js.JsObject;
  } catch (_) {
    return null;
  }
}

void telegramReady() {
  try {
    _webApp()?.callMethod('ready');
  } catch (_) {}
}

void telegramExpand() {
  try {
    _webApp()?.callMethod('expand');
  } catch (_) {}
}

void telegramClose() {
  try {
    _webApp()?.callMethod('close');
  } catch (_) {}
}

Map<String, String> telegramUser() {
  try {
    final webApp = _webApp();
    if (webApp == null) return {};
    final initData = webApp['initDataUnsafe'];
    if (initData == null) return {};
    final u = (initData as js.JsObject)['user'];
    if (u == null) return {};
    final jsUser = u as js.JsObject;
    return {
      'id': (jsUser['id'] ?? '').toString(),
      'first_name': (jsUser['first_name'] ?? '').toString(),
      'last_name': (jsUser['last_name'] ?? '').toString(),
      'username': (jsUser['username'] ?? '').toString(),
    };
  } catch (_) {
    return {};
  }
}

String telegramColorScheme() {
  try {
    return (_webApp()?['colorScheme'] ?? 'light').toString();
  } catch (_) {
    return 'light';
  }
}

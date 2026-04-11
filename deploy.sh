#!/bin/bash
set -e

echo "🌿 Hadiya — Firebase Deploy"
echo "================================"

# 1. Mini App build
echo ""
echo "📱 [1/4] Mini App build qilinmoqda..."
flutter build web \
  --dart-define=APP_MODE=miniapp \
  --web-renderer html \
  --release \
  --output build/web_miniapp

# web_miniapp papkasidan index.html ni ko'chiramiz
cp web_miniapp/index.html build/web_miniapp/index.html

echo "✅ Mini App build tayyor"

# 2. Admin build
echo ""
echo "🖥️  [2/4] Admin Panel build qilinmoqda..."
flutter build web \
  --dart-define=APP_MODE=admin \
  --web-renderer html \
  --release \
  --output build/web_admin

# web_admin papkasidan index.html ni ko'chiramiz
cp web_admin/index.html build/web_admin/index.html

echo "✅ Admin build tayyor"

# 3. Firestore rules deploy
echo ""
echo "🔥 [3/4] Firestore rules deploy qilinmoqda..."
firebase deploy --only firestore:rules --project hadaya-4d357

# 4. Hosting deploy
echo ""
echo "🚀 [4/4] Hosting deploy qilinmoqda..."
firebase deploy --only hosting --project hadaya-4d357

echo ""
echo "================================"
echo "✅ Deploy muvaffaqiyatli yakunlandi!"
echo ""
echo "🌐 Mini App:  https://hadaya-4d357.web.app"
echo "⚙️  Admin:     https://hadiya-admin.web.app"
echo "================================"

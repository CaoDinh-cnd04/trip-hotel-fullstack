#!/bin/bash

echo "=== FACEBOOK ANDROID KEY HASH GENERATOR ==="
echo ""

# Kiểm tra hệ điều hành
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # Windows
    KEYSTORE_PATH="$USERPROFILE/.android/debug.keystore"
else
    # macOS/Linux  
    KEYSTORE_PATH="$HOME/.android/debug.keystore"
fi

echo "Đường dẫn keystore: $KEYSTORE_PATH"
echo ""

if [ -f "$KEYSTORE_PATH" ]; then
    echo "Tìm thấy debug keystore!"
    echo "Đang tạo key hash..."
    echo ""
    
    # Tạo key hash
    keytool -exportcert -alias androiddebugkey -keystore "$KEYSTORE_PATH" -storepass android -keypass android | openssl sha1 -binary | openssl base64
    
    echo ""
    echo "✅ Key hash đã được tạo!"
    echo "📋 Copy đoạn text trên và paste vào Facebook Developer Console"
    echo ""
    echo "🔗 Link cấu hình: https://developers.facebook.com/apps/1361581552264816/settings/basic/"
    
else
    echo "❌ Không tìm thấy debug.keystore"
    echo ""
    echo "💡 Hướng dẫn:"
    echo "1. Chạy 'flutter run' một lần để tạo debug keystore"
    echo "2. Hoặc tạo keystore thủ công bằng Android Studio"
    echo ""
fi

echo ""
echo "Package Name Android: com.example.hotel_mobile"
echo "Class Name: com.example.hotel_mobile.MainActivity"
echo ""
read -p "Nhấn Enter để thoát..."
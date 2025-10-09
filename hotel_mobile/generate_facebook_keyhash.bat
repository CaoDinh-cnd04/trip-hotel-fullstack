@echo off
echo ========================================
echo    TẠO KEY HASH CHO FACEBOOK LOGIN
echo ========================================
echo.

REM Tìm keytool từ Android Studio
set "ANDROID_STUDIO_JDK=C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
set "JAVA_HOME_KEYTOOL=%JAVA_HOME%\bin\keytool.exe"

echo Đang tìm keytool...
echo.

REM Kiểm tra Android Studio JDK
if exist "%ANDROID_STUDIO_JDK%" (
    echo ✅ Tìm thấy keytool từ Android Studio
    echo Đường dẫn: %ANDROID_STUDIO_JDK%
    echo.
    echo Đang tạo Facebook Key Hash...
    echo.
    
    REM Tạo key hash cho Facebook (cần OpenSSL)
    echo ⚠️  LƯU Ý: Cần cài đặt OpenSSL để tạo key hash
    echo Download từ: https://wiki.openssl.org/index.php/Binaries
    echo.
    echo Command để chạy sau khi có OpenSSL:
    echo.
    echo "%ANDROID_STUDIO_JDK%" -exportcert -alias androiddebugkey -keystore "%USERPROFILE%\.android\debug.keystore" -storepass android -keypass android ^| openssl sha1 -binary ^| openssl base64
    echo.
    goto :manual
)

REM Kiểm tra JAVA_HOME
if exist "%JAVA_HOME_KEYTOOL%" (
    echo ✅ Tìm thấy keytool từ JAVA_HOME
    echo Đường dẫn: %JAVA_HOME_KEYTOOL%
    echo.
    echo Command để chạy sau khi có OpenSSL:
    echo.
    echo "%JAVA_HOME_KEYTOOL%" -exportcert -alias androiddebugkey -keystore "%USERPROFILE%\.android\debug.keystore" -storepass android -keypass android ^| openssl sha1 -binary ^| openssl base64
    echo.
    goto :manual
)

echo ❌ Không tìm thấy keytool!
echo.
echo Hãy cài đặt:
echo 1. Android Studio
echo 2. Hoặc Java JDK
echo.
goto :end

:manual
echo ========================================
echo 🔧 CÁCH TẠO KEY HASH CHO FACEBOOK:
echo ========================================
echo.
echo BƯỚC 1: Cài đặt OpenSSL
echo - Download từ: https://wiki.openssl.org/index.php/Binaries
echo - Hoặc dùng Git Bash (có sẵn OpenSSL)
echo.
echo BƯỚC 2: Chạy command trong Git Bash:
echo.
echo keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android ^| openssl sha1 -binary ^| openssl base64
echo.
echo BƯỚC 3: Copy kết quả (dạng base64) vào Facebook Developer Console
echo.
echo ========================================
echo 🎯 FACEBOOK DEVELOPER CONSOLE:
echo ========================================
echo 1. Vào: https://developers.facebook.com/apps/1361581552264816/
echo 2. Settings ^> Basic ^> Android Platform
echo 3. Paste Key Hash vào ô "Key Hashes"
echo 4. Save changes
echo.
echo ========================================
echo 📱 THÔNG TIN APP:
echo ========================================
echo Package Name: com.example.hotel_mobile
echo Class Name: com.example.hotel_mobile.MainActivity
echo.

:end
echo.
pause
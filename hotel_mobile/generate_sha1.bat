@echo off
echo ========================================
echo    TẠO SHA-1 FINGERPRINT CHO FIREBASE
echo ========================================
echo.

REM Tìm keytool từ Android Studio
set "ANDROID_STUDIO_JDK=C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
set "FLUTTER_JDK=%USERPROFILE%\AppData\Local\Android\Sdk\tools\bin\keytool.exe"
set "JAVA_HOME_KEYTOOL=%JAVA_HOME%\bin\keytool.exe"

echo Đang tìm keytool...
echo.

REM Kiểm tra Android Studio JDK
if exist "%ANDROID_STUDIO_JDK%" (
    echo ✅ Tìm thấy keytool từ Android Studio
    echo Đường dẫn: %ANDROID_STUDIO_JDK%
    echo.
    echo Đang tạo SHA-1 fingerprint...
    echo.
    "%ANDROID_STUDIO_JDK%" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
    goto :found
)

REM Kiểm tra Flutter SDK
if exist "%FLUTTER_JDK%" (
    echo ✅ Tìm thấy keytool từ Flutter
    echo Đường dẫn: %FLUTTER_JDK%
    echo.
    echo Đang tạo SHA-1 fingerprint...
    echo.
    "%FLUTTER_JDK%" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
    goto :found
)

REM Kiểm tra JAVA_HOME
if exist "%JAVA_HOME_KEYTOOL%" (
    echo ✅ Tìm thấy keytool từ JAVA_HOME
    echo Đường dẫn: %JAVA_HOME_KEYTOOL%
    echo.
    echo Đang tạo SHA-1 fingerprint...
    echo.
    "%JAVA_HOME_KEYTOOL%" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
    goto :found
)

REM Không tìm thấy keytool
echo ❌ Không tìm thấy keytool!
echo.
echo 💡 GIẢI PHÁP:
echo 1. Cài đặt Java JDK: https://www.oracle.com/java/technologies/downloads/
echo 2. Hoặc sử dụng Android Studio có sẵn JDK
echo 3. Hoặc sử dụng Flutter Doctor để kiểm tra cài đặt
echo.
echo 🔧 CÁC ĐƯỜNG DẪN THƯỜNG GẶP:
echo - Android Studio: C:\Program Files\Android\Android Studio\jbr\bin\
echo - Flutter: %USERPROFILE%\AppData\Local\Android\Sdk\tools\bin\
echo - Java JDK: C:\Program Files\Java\jdk-xx\bin\
echo.
goto :end

:found
echo.
echo ========================================
echo 📋 HƯỚNG DẪN TIẾP THEO:
echo ========================================
echo 1. Copy đoạn SHA1 fingerprint ở trên
echo 2. Vào Firebase Console: https://console.firebase.google.com/
echo 3. Chọn project "trip-hotel"
echo 4. Vào Settings ^> Your apps ^> Android app
echo 5. Nhấn "Add fingerprint"
echo 6. Paste SHA1 fingerprint
echo.

:end
echo.
pause
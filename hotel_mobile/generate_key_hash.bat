@echo off
echo Tao Key Hash cho Facebook Android App

echo.
echo 1. Debug Key Hash (dung cho development):
echo.

cd /d "%USERPROFILE%\.android"
if exist debug.keystore (
    keytool -exportcert -alias androiddebugkey -keystore debug.keystore -storepass android -keypass android | openssl sha1 -binary | openssl base64
    echo.
    echo Copy key hash tren va paste vao Facebook Developer Console
) else (
    echo Khong tim thay debug.keystore. Hay chay 'flutter run' truoc.
)

echo.
echo 2. Neu ban da co release keystore, thay doi duong dan ben duoi:
echo keytool -exportcert -alias [your-key-alias] -keystore [path-to-your-keystore] | openssl sha1 -binary | openssl base64

pause
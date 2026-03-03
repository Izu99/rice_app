@echo off
echo Cleaning project...
call flutter clean
echo Getting dependencies...
call flutter pub get
echo Building APK...
call flutter build apk --release
echo Build Complete!
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo APK location: build\app\outputs\flutter-apk\app-release.apk
    explorer build\app\outputs\flutter-apk
) else (
    echo Build failed or APK not found.
)
pause

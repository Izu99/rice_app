7# APK Build Checklist for Flutter Projects

Use this checklist to prepare and build an APK for a new or different app using an existing Flutter project.

## 1. Update App Metadata
- **App Name**
  - Update in `android/app/src/main/AndroidManifest.xml` (`android:label`)
  - Update in `lib/main.dart` or wherever your app title is set
- **Application ID (Package Name)**
  - Change `applicationId` in `android/app/build.gradle.kts` (or `build.gradle`)
  - Must be unique (e.g., `com.yourcompany.newapp`)
- **Version Code & Version Name**
  - Update `versionCode` and `versionName` in `android/app/build.gradle.kts`
- **App-level Configuration**
  - Update `name`, `description`, etc. in `pubspec.yaml`

## 2. Update App Assets
- **App Icon**
  - Replace icon files in `assets/icons/`
  - Update icon reference in `android/app/src/main/AndroidManifest.xml`
- **Images, Fonts, etc.**
  - Replace or update assets in `assets/` as needed

## 3. Update Backend/Service Configurations
- **Firebase (if used)**
  - Replace `google-services.json` in `android/app/` if using a different Firebase project
- **Other Service Configs**
  - Update any other backend or API configuration files

## 4. Update Permissions
- Review and update permissions in `android/app/src/main/AndroidManifest.xml`

## 5. Clean and Build APK
- Run `flutter clean` to clear old builds
- Run `flutter pub get` to fetch dependencies
- Run `flutter build apk` to generate the APK
  - Output will be in `build/app/outputs/flutter-apk/app-release.apk`

## 6. Test APK
- Install the APK on a device or emulator and verify all features

---

**Tip:**
- Always use unique application IDs for each app to avoid conflicts.
- Double-check all branding, assets, and configuration before release.

---

_You can copy this file to any Flutter project as a reference for APK preparation and building._

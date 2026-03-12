# Google OAuth Implementation Guide (Flutter & Node.js)

This guide details the implementation of a modern, secure Google Sign-In system using Flutter (v7.2.0+) and a Node.js backend. This setup does **not** require Firebase.

---

## 1. Google Cloud Console Setup 🛠️

You must create **two** separate OAuth 2.0 Client IDs in the [Google Cloud Console](https://console.cloud.google.com/apis/credentials).

### A. Android Client ID (The "Identity")
*   **Purpose**: Authorizes your specific Android app to use Google Sign-In.
*   **Application Type**: Android.
*   **Package Name**: Must match your `applicationId` (e.g., `com.ricemill.erp`).
*   **SHA-1 Fingerprint**: Required (see Section 2).

### B. Web Application Client ID (The "Token Generator")
*   **Purpose**: Used by the Flutter app to request an `idToken` that the backend can verify.
*   **Application Type**: Web application.
*   **Authorized JavaScript origins**: Leave empty for mobile-only.
*   **Authorized redirect URIs**: Leave empty for mobile-only.
*   **Note**: This `Client ID` is the one you will put in your code as `serverClientId`.

---

## 2. Obtaining the SHA-1 Fingerprint 🔑

To identify your app to Google, you need the SHA-1 of your signing key.

1.  Open terminal in your Flutter project's `android` folder.
2.  Run: `.\gradlew signingReport`
3.  Look for the **`debug`** or **`release`** block and copy the **SHA1** value.
4.  Paste this into your **Android Client ID** in the Google Cloud Console.

---

## 3. Flutter Frontend Implementation 📱

### Dependencies (`pubspec.yaml`)
```yaml
dependencies:
  google_sign_in: ^7.2.0
```

### Android Native Setup (`android/app/build.gradle.kts`)
Starting with version 7.0, the plugin uses the Android Credential Manager. If not using Firebase, add these manually:
```kotlin
dependencies {
    implementation("com.google.android.gms:play-services-auth:21.0.0")
    implementation("androidx.credentials:credentials:1.2.2")
    implementation("androidx.credentials:credentials-play-services-auth:1.2.2")
}
```

### Initialization (`AuthCubit` / Service)
You must initialize the plugin with the **Web Client ID**.
```dart
final GoogleSignIn _googleSign = GoogleSignIn.instance;

Future<void> initialize() async {
  await _googleSign.initialize(
    serverClientId: '816656670559-ucfdqo2gn4h9gst50rtfi9sjlm8428ja.apps.googleusercontent.com',
  );
}
```

### Sign-In Logic
```dart
Future<void> login() async {
  // 1. Trigger the popup
  final GoogleSignInAccount? googleUser = await _googleSign.authenticate(
    scopeHint: ['email', 'profile'],
  );

  // 2. Get the idToken
  final GoogleSignInAuthentication auth = await googleUser!.authentication;
  final String? idToken = auth.idToken;

  // 3. Send idToken to your backend
  await myApi.verifyGoogleLogin(idToken);
}
```

---

## 4. Node.js Backend Verification 🖥️

### Dependencies
```bash
npm install google-auth-library
```

### Verification Logic (`authController.js`)
```javascript
const { OAuth2Client } = require('google-auth-library');
const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

exports.googleLogin = async (req, res) => {
  const { idToken } = req.body;

  try {
    const ticket = await client.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID, // Use: 816656670559-ucfdqo2gn4h9gst50rtfi9sjlm8428ja.apps.googleusercontent.com
    });

    const payload = ticket.getPayload();
    const { email, name, sub: googleId } = payload;

    // Check if user exists in DB
    // IMPORTANT: This app does NOT allow auto-registration via Google.
    // Users must be registered manually by an admin first.
    let user = await User.findOne({ email }).populate('companyId');
    
    if (!user) {
        return res.status(401).json({ 
            success: false,
            message: "Account not found. Please register manually first." 
        });
    }

    // Link Google ID if it's not already set
    if (!user.googleId) {
      user.googleId = googleId;
      await user.save({ validateBeforeSave: false });
    }

    // Generate JWT and return
    const token = user.generateAuthToken();
    res.json({ success: true, user, token });

  } catch (error) {
    res.status(401).json({ success: false, message: "Invalid Google Token" });
  }
};
```

---

## 5. Security & Best Practices 🛡️

*   **No Client Secret on Mobile**: Never store the Client Secret in the Flutter app. Mobile apps are "Public Clients" and cannot keep secrets safely.
*   **Audience Check**: Always ensure the `audience` in the backend verification matches your `Web Client ID`.
*   **Same-Network Testing**: When testing a local backend from a real phone, use the computer's local IP (e.g., `192.168.1.XX`) instead of `localhost`.
*   **Production Environment**: Ensure your VPS backend `.env` has the correct `GOOGLE_CLIENT_ID`.

---
*Created for: Rice Mill ERP Implementation*

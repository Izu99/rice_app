# 🚀 Google OAuth Setup for Rice Mill ERP

This application uses Google Sign-In with a **Node.js Backend (No Firebase)**.

### 🔑 Active Google Client ID (Rice Mill App)
**Web Client ID:** `816656670559-ucfdqo2gn4h9gst50rtfi9sjlm8428ja.apps.googleusercontent.com`
*(Verified and added to both Frontend and Backend)*

---

## 1. Quick Setup (Developer)

### 📱 Flutter Client (`AuthCubit`)
The client must initialize the `GoogleSignIn` instance with the `serverClientId`:
```dart
await _googleSignIn.initialize(
  serverClientId: '816656670559-ucfdqo2gn4h9gst50rtfi9sjlm8428ja.apps.googleusercontent.com',
);
```

### 🖥️ Node.js Backend (`.env`)
The server must verify the `idToken` against this same ID:
```env
GOOGLE_CLIENT_ID=816656670559-ucfdqo2gn4h9gst50rtfi9sjlm8428ja.apps.googleusercontent.com
```

---

## 2. Important Rules ⚠️

1.  **Manual Registration Only**: This app does NOT allow users to register via Google. A user must already exist in the database with their email.
2.  **First Time Login**: On the first Google login, the app will link the user's `googleId` to their existing account.
3.  **No Client Secret**: Never put the `GOOGLE_CLIENT_SECRET` in the Flutter app. It is only for the backend.

---

## 3. How it Works (Flow)
1.  **App**: User clicks "Sign in with Google".
2.  **App**: Google returns an `idToken`.
3.  **App**: Sends `idToken` to `POST /api/auth/google`.
4.  **Server**: Verifies the token using `google-auth-library`.
5.  **Server**: Checks if the email exists in our Database.
6.  **Server**: Returns a custom JWT token if authorized.

---
*Refer to `OAUTH_SETUP_GUIDE.md` for full implementation details.*

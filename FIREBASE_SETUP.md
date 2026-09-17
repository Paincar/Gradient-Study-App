# Firebase & Google Authentication Setup for Gradient

To enable Google Sign-In and Cloud Note Sync for Gradient:

## 1. Firebase Project Setup
1. Open the [Firebase Console](https://console.firebase.google.com/).
2. Create or select your Firebase project (e.g. gradient-study-app).
3. Click **Add app** and choose **Android**.

## 2. Register Android Application
- **Android package name:**
  com.focuspath.app
- **App nickname:**
  Gradient
- **Debug signing certificate SHA-1:**
  F6:84:D5:F0:83:70:18:6A:4F:12:82:AF:DF:95:70:D5:1B:59:38:A7
- **Debug signing certificate SHA-256 (recommended):**
  F7:D6:60:7F:0D:E5:32:79:60:8C:E9:56:22:C7:9E:E1:C7:E0:8A:ED:E7:B7:E7:09:A8:F7:35:4A:05:A5:18:9F

> **Note:** In Gradient Settings, you can tap **Copy SHA-1 Key** anytime to copy this fingerprint with 1 click.

## 3. Enable Google Sign-In Provider
1. In Firebase Console, go to **Build** -> **Authentication**.
2. Under the **Sign-in method** tab, click **Google**.
3. Toggle **Enable**, configure support email, and click **Save**.

## 4. Download and Place configuration file
1. In Firebase Console **Project settings** -> **Your apps**, click **Download google-services.json**.
2. Save or copy the downloaded file to:
   ndroid/app/google-services.json
3. Rebuild the app (lutter run or lutter build apk).

## 5. Offline Fallback (No Setup Required)
If you prefer not to set up Firebase, Gradient includes a **Local Student Profile** fallback:
- Open Gradient -> **Settings**.
- Tap **Continue with Student Profile (Offline/Local)**.
- Enter your name to store your notes and study stats locally on your device.

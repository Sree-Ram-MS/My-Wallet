# My Wallet 🪙

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=flat&logo=Dart&logoColor=white)](https://dart.dev)
[![Gemini](https://img.shields.io/badge/Google%20Gemini-AI-purple?style=flat&logo=google&logoColor=white)](https://ai.google.dev)
[![Android](https://img.shields.io/badge/Android-3DDC84?style=flat&logo=android&logoColor=white)](https://developer.android.com)

**My Wallet** is a premium, secure, and highly intelligent personal finance assistant built using Flutter. It is designed to make budgeting and expense tracking effortless through standard manual entries and an advanced, voice-first **Gemini AI Quick Entry** interface.

---

## 🌟 Key Features

### 🎙️ Voice-First Gemini AI Entry
- **Dictate Transactions**: Simply speak your transaction (e.g., *"spent 150 on delicious pizza just now using my cash wallet"*).
- **Auto-Start Listening**: The microphone activates automatically the moment you open the AI Entry sheet.
- **Smart Parsing**: Leverages the **Google Gemini REST API** (`gemini-2.5-flash`) to parse raw audio transcripts into double amounts, accounts, categories, and transaction dates.
- **Auto-Submit on Silence**: Recognizes when you're done speaking and automatically starts analysis without needing button taps.
- **Typing Interruption**: If you decide to type instead, the active microphone session halts immediately to prevent conflicts.
- **One-Click Retry**: "Try Again" clears the controller and instantly restarts listening.

### 📊 Rich Dashboards & Analytics
- **Glassmorphism Metrics**: High-contrast, premium cards showing total balance, inflows, outflows, and net savings.
- **Categories Donut Chart**: Visual distribution of monthly expenses powered by `fl_chart`.
- **Historical Trend Line Graph**: Interactive chronological graph tracking net balance trends.

### 🛡️ Security & Privacy
- **Biometric Lock**: Built-in support for Android Fingerprint / Face Unlock / Passcode using the `local_auth` package.
- **Encryption**: Secure data layers protecting transaction notes and offline configurations using local AES encryption.
- **Full Offline Control**: Runs locally on a SQLite database (`sqflite`). Your financial data stays on your device.

### ⚙️ Financial Tools
- **Multiple Accounts**: Manage cash, bank accounts, and credit cards with distinct balances and inflows.
- **Custom Categories**: Organize transactions with specific colors and icons.
- **Planned Payments**: Schedule recurring or future transactions.
- **Debts & Credits Tracker**: Log money lent to or borrowed from contacts.
- **CSV & Excel Import**: Easily import statements or export transaction logs using excel sheet formats.
- **Google Drive Backup**: Upload encrypted database backups directly to your personal Google Drive storage.

---

## 🛠️ Architecture & Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart SDK `^3.10.4`)
- **State Management**: [Provider](https://pub.dev/packages/provider) for clean, decoupled reactive bindings.
- **Database**: [SQLite](https://pub.dev/packages/sqflite) for high-performance offline ledger storage.
- **AI Core**: Google Gemini REST API using `gemini-2.5-flash` model.
- **Voice Dictation**: [SpeechToText](https://pub.dev/packages/speech_to_text) for native audio-to-text conversion.
- **Biometrics**: [Local Auth](https://pub.dev/packages/local_auth) for native biometric lock-screen integrations.

---

## 🚀 Getting Started & Android Configuration

### Prerequisites
1. **Flutter SDK**: Ensure you have Flutter `3.10.4` or higher installed.
2. **Android SDK**: Android API Level 23 (Android 6.0) or higher.
3. **Gemini API Key**: Obtain a free API key from Google AI Studio.

### Android Permissions Configuration
The required permissions are pre-configured in [AndroidManifest.xml](file:///c:/Users/srmsm/Desktop/My%20apps/my_wallet/android/app/src/main/AndroidManifest.xml):
- `android.permission.RECORD_AUDIO` - For voice-to-text dictation.
- `android.permission.USE_BIOMETRIC` - For fingerprint/face lock screen.
- `android.permission.INTERNET` - For syncing backups and contacting the Gemini API.

### Setup and Running Instructions

1. Clone the repository and navigate to the project directory:
   ```bash
   cd my_wallet
   ```

2. Download all Flutter package dependencies:
   ```bash
   flutter pub get
   ```

3. Build and generate the native launcher icons:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

4. Run the application on an emulator or connected Android device:
   ```bash
   flutter run
   ```

5. **API Key Setup**: Once the app is running, navigate to **Settings & Cloud Backup** in the drawer menu, paste your Google Gemini API Key, and save. You are now ready to speak to your wallet!

---

## 🎨 Theme Support
Includes full Material 3 custom theme architectures:
- **Deep Indigo / Blue Gradient** light theme for clean, high-contrast daylight use.
- **Dark Glossy Metallic / Obsidian** dark theme styled for evening use with neon-accented glowing buttons.

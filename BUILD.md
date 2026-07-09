# Ghostgram iOS Compilation Guide

> **Important**: Notifications, calls, and some other cloud-dependent features may not be fully implemented in this fork's development builds. For daily use, it is recommended to keep the official Telegram App installed.

## 🛠 Prerequisites

- **macOS**: Latest version recommended.
- **Xcode**: See `versions.json` for the exact required version.
- **Bazel**: Managed via the build system.
- **Python**: 3.x

---

## 🚀 Quick Start

### 1. Obtain Telegram API Credentials
1. Go to [my.telegram.org](https://my.telegram.org).
2. Log in and create a new application to get your `api_id` and `api_hash`.

### 2. Get the Source Code
```bash
git clone --recursive -j8 https://github.com/TelegramMessenger/Telegram-iOS.git
# Note: In this fork, ensure you have all submodules
```

### 3. Setup Xcode Configuration
1. Generate a random 8-character hex identifier:
   ```bash
   openssl rand -hex 8
   ```
2. Create a dummy Xcode project named `Telegram` with organization identifier `org.<YOUR_HEX_ID>`.
3. Locate your **Team ID** in Keychain Access (Organizational Unit of your Apple Development certificate).
4. Edit `build-system/template_minimal_development_configuration.json` with your credentials and Team ID.

### 4. Generate Xcode Project
```bash
python3 build-system/Make/Make.py \
    --cacheDir="$HOME/telegram-bazel-cache" \
    generateProject \
    --configurationPath=build-system/template_minimal_development_configuration.json \
    --xcodeManagedCodesigning
```

---

## 🏗 Advanced Build Options

### Building an IPA (Release)
1. Configure `build-system/appstore-configuration.json`.
2. Ensure you have the correct provisioning profiles.
3. Run:
```bash
python3 build-system/Make/Make.py \
    --cacheDir="$HOME/telegram-bazel-cache" \
    build \
    --configurationPath=your_config.json \
    --codesigningInformationPath=your_profiles_dir \
    --buildNumber=100001 \
    --configuration=release_arm64
```

### Simulator Build (No Codesigning)
Add `--disableProvisioningProfiles` to the generation command to build for the simulator without needing a development certificate.

---

## ❓ FAQ & Troubleshooting

### "build-request.json not updated yet"
If Xcode hangs with this message, cancel the build and restart it.

### "no such package @rules_xcodeproj_generated"
This usually happens after a system restart or clearing Bazel cache. Re-run the `generateProject` command.

### Overriding Xcode Version
If you have a newer/older Xcode than what is specified in `versions.json`, use:
```bash
python3 build-system/Make/Make.py --overrideXcodeVersion generateProject ...
```

---
Report all issues/bugs on Telegram [@ceopoco](https://t.me/ceopoco)

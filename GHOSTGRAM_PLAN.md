# Fork plan & status

Base: `ichmagmaus111/ghostgram` (a Telegram-iOS fork). GPLv2 — publishing your
fork means publishing your source.

## Current state (verified 2026-07-08)
- Upstream base: **Telegram-iOS 12.2.3** (`versions.json`). Latest upstream is **12.8**.
- Toolchain pinned: Xcode 26.2, macOS 26, Bazel 8.4.2.
- Features already implemented: anti-delete (`AntiDeleteManager`, `DeletedMessageAttribute`),
  edit history (`EditHistoryManager`, `LocalEditManager`), ghost mode (`GhostModeManager`).
- Default branch: `main`.

## Done in this pass
1. **Security hardening (the "encryption" ask).** Recovered message content and
   pre-edit originals used to be written **in plaintext to `UserDefaults`**.
   Added `submodules/TelegramCore/Sources/GhostSecurity/SecureStore.swift`:
   AES-GCM (CryptoKit) with a 256-bit key in the Keychain
   (`AfterFirstUnlockThisDeviceOnly`, device-bound, not in backups), payloads
   written as backup-excluded, file-protected files. `AntiDeleteManager` and
   `EditHistoryManager` now persist through it, with a one-time migration that
   moves and then wipes the old plaintext. Optional Face ID gate
   (`authenticateForViewing`) for the UI, kept separate from the storage key so
   background message capture still works.
2. **Fixed CI** (`.github/workflows/build.yml`): `macos-15` (has Xcode 26.2),
   trigger on `main`, aggressive disk cleanup (remove unused Xcodes/simulators),
   Bazel cache step, unsigned IPA via `fake-codesigning`, artifact + release upload.

## Build → sign → sideload
- CI builds an **unsigned** `Telegram.ipa` (throwaway self-signed cert).
- Download the artifact, **re-sign in ESign / AltStore / Sideloadly** with your
  Apple ID, install. Free Apple IDs cap app extensions — you may have to strip
  some (share/notification/widget/watch) before signing.

## What must NOT be built here
- This Linux box cannot compile Telegram-iOS (needs macOS + Xcode + Bazel).
  All builds happen on CI or a Mac.

## Roadmap / open work
1. **Bump 12.2.3 → 12.8.** Hard: the fork history is squashed (1 commit), so it
   is a manual re-port, not a clean rebase. Plan: diff the fork against a clean
   `TelegramMessenger/Telegram-iOS` v12.2.3 tag to isolate exactly the fork's
   changes, then re-apply that delta on the v12.8 tag. The fork's own files
   (AntiDelete/, GhostMode/, GhostSecurity/) port cleanly; the risk is the small
   hook points inside upstream files (update processing, chat UI) that upstream
   may have moved.
2. **Optimization.** Build side: self-hosted/warm Bazel cache (below). App side:
   the anti-delete archive is an in-memory array re-encoded on every write — fine
   for now, switch to an incremental/SQLite-backed store if archives get large.
3. **Faster iterative builds (caching).** Hosted GitHub caches are capped ~10GB
   and Telegram's Bazel output is far bigger, so a full warm cache does not fit.
   Real options for a fast build-fix loop:
   - **Self-hosted Mac runner** — keeps the Bazel output between runs, so a
     rebuild after a one-file fix is incremental (minutes, not ~1h). Best option.
   - **Remote Bazel cache** (BuildBuddy/HTTP cache) if staying on hosted runners.
4. **Branding/rename** — bundle id, display name, scheme; pick a name first.

## Security reality (be honest in the UI)
- You can encrypt everything **on this device** strongly (done above).
- You **cannot** add end-to-end encryption to normal Telegram *cloud* chats from
  a client fork — the server holds that data and only Secret Chats are E2E,
  device-to-device. Label the feature "Local encryption / App Lock", not "E2E".

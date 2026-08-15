# QuotaBar

QuotaBar is a local-first macOS menu bar application for monitoring Codex, OpenRouter, and DeepSeek quotas and balances.

## Current foundation

- Native SwiftUI `MenuBarExtra` application for macOS 14 or newer.
- Direct provider connections; no CPA service or private relay is required.
- Codex reads the active local Codex Desktop/CLI login from `~/.codex/auth.json` without modifying it.
- DeepSeek and OpenRouter secrets are stored in macOS Keychain.
- System material-based glass appearance with automatic light and dark mode support.
- Provider failures are isolated so one unavailable channel does not hide the others.

Codex quota endpoints are internal, undocumented ChatGPT endpoints and can change without notice. QuotaBar treats Codex as read-only and never redeems reset credits.

## Build and test

The repository is a Swift Package so it can be opened directly in Xcode or built from the command line:

```sh
swift build
swift test
```

If a standalone Command Line Tools installation reports a Swift/SDK version mismatch, install the matching Xcode release or use `Scripts/package.sh`, which includes a local Command Line Tools compatibility fallback for packaging.

To create a local `.app` bundle:

```sh
./Scripts/package.sh
```

Then double-click `dist/QuotaBar.app`. When launched outside an Applications folder, QuotaBar installs itself automatically and relaunches the installed copy:

- `/Applications/QuotaBar.app` when the system Applications directory is writable;
- otherwise `~/Applications/QuotaBar.app`, without requesting an administrator password.

If the same or a newer build is already installed, the temporary copy opens the installed app instead of overwriting it. A newer build safely replaces an older installed build.

The initial bundle is intended for local development. Public distribution should use Developer ID signing and notarization.

## Credentials

Open the menu bar panel, select **Settings**, and enter:

- a DeepSeek API key;
- an OpenRouter API key;
- optionally, an OpenRouter Management Key for account-wide credit balance.

QuotaBar never commits credentials to the repository or stores them in preferences files.

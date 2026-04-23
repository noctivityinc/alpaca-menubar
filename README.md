# AlpacaBar — Native Mac Menu Bar App (Swift)

A native SwiftUI menu bar app that shows your Alpaca account's daily P&L. No Python, no dependencies, no terminal.

## Requirements
- macOS 13 (Ventura) or later
- Xcode 14+

## How to Build & Run

1. Clone the repo
2. Open `AlpacaBar/AlpacaBar.xcodeproj` in Xcode
3. Hit **⌘R** to build and run
4. A `📈` icon appears in your menu bar
5. Click it → click **Settings** → enter your API credentials

## First Launch

In Settings:
- Enter your Alpaca **API Key ID** and **Secret Key**
- Choose **Paper** or **Live**
- Toggle **Launch at Login** if you want it to auto-start
- Hit **Save**

## Menu Bar

- **Market hours (9:30–4 PM ET):** `▲ +1.23%  +$1,234.56`
- **Outside hours:** `📈 +1.23%`
- **Click** → shows equity, buying power, cash, open positions

## Credentials

Stored securely in macOS Keychain. Never written to disk in plaintext.

## To Distribute (no App Store)

In Xcode: **Product → Archive → Distribute App → Direct Distribution**

This produces a signed `.app` you can drag to `/Applications` on any Mac.

## File Structure

```
AlpacaBar/
├── AlpacaBar.xcodeproj/
└── AlpacaBar/
    ├── AlpacaBarApp.swift       # App entry point + MenuBarExtra
    ├── AccountViewModel.swift   # Data fetching, state, formatting
    ├── KeychainHelper.swift     # Secure credential storage
    ├── MenuBarLabel.swift       # The text shown in the menu bar
    ├── MenuBarView.swift        # Dropdown panel
    └── SettingsView.swift       # Credentials + launch-at-login
```

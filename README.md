# GreenWallet

Mobile wallet for Nusacoin (NUX) mainnet and testnet, using
[electrs](https://github.com/Melkisedek03/electrs) as backend over the Electrum protocol.

**App in constant development.**

**Use at own risk.**

## Features

- Send and receive NUX on-chain (mainnet + testnet)
- Custom Electrum (electrs) server support — point the wallet at any compatible server
- Seed backup and restore (BIP39)
- Dark and light themes (Emerald Deep)

## Backend

GreenWallet speaks the Electrum protocol (v1.4) to electrs servers running the
Nusacoin fork of electrs. The default server is `apinux.taobot.org`
(TCP, port 50009). Custom servers can be added in-app.

## Development

**Build coinlib**
This repository relies on
[coinlib.](https://github.com/Melkisedek03/coinlib "https://github.com/Melkisedek03/coinlib")
(branch `nux/network`, based on coinlib 4.1.0 with the Nusacoin networks added).
Please follow the build instructions for your OS in the coinlib README.

**Update icons**
`dart run flutter_launcher_icons:main`

**Update Hive adapters**
`dart run build_runner build`

**Update splash screen**
`dart run flutter_native_splash:create`

## Run e2e tests

`flutter drive --target=test_driver/app.dart --driver=test_driver/key_new.dart`
`flutter drive --target=test_driver/app.dart --driver=test_driver/key_imported.dart`

## License

GreenWallet is released under the [AGPL-3.0](LICENSE) license.

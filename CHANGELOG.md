# Changelog

## Unreleased

### Rebranding to GreenWallet
- New app icons, splash screen, and Emerald Deep color theme (dark and light)
- App renamed to GreenWallet (`com.nusa.greenwallet`)
- Default Electrum server: `apinux.taobot.org` (TCP, port 50009)
- Custom notification sound
- README rewritten for Nusacoin; EN/ID translations cleaned of Peercoin references
- Dart package renamed to `greenwallet`

### Cleanup
- Disabled ROOST/FROST experimental features
- Removed price ticker and Buy Peercoin button
- Fees via `blockchain.estimatefee` (15s timeout, fixed fallback)
- Transaction version 2

### Nusacoin chain parameters
- Added Nusacoin mainnet and testnet (P2PKH 53/111, P2SH 75/196, HRP `nu`/`tn`)
- Custom HD version bytes (`nuxp`/`nuxs`, `nxtp`/`nxts`)
- `tcp://` Electrum transport support
- Minimum dust 546 nusan
- coinlib fork with Nusacoin networks

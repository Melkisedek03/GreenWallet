import 'dart:math';

import 'package:coinlib_flutter/coinlib_flutter.dart';

import 'coin.dart';

// TODO(GreenWallet): set the real public Electrum hostnames once the NUX
// electrs endpoints are published. Users can already add custom servers
// via the in-app server settings in the meantime.
const nusacoinElectrumHost = 'electrum.nusacoin.example';
const nusacoinTestnetElectrumHost = 'testnet-electrum.nusacoin.example';

class AvailableCoins {
  static final Map<String, Coin> _availableCoinList = {
    'peercoin': Coin(
      name: 'peercoin',
      displayName: 'Peercoin',
      uriCode: 'peercoin',
      letterCode: 'PPC',
      iconPath: 'assets/icon/ppc-icon-48.png',
      iconPathTransparent: 'assets/icon/ppc-icon-white-48.png',
      networkType: Network.mainnet,
      opreturnSize: 256,
      fractions: 6,
      minimumTxValue: 10000,
      fixedFee: true,
      fixedFeePerKb: 0.01,
      explorerUrl: 'https://blockbook.peercoin.net',
      genesisHash:
          '0000000032fe677166d54963b62a4677d8957e87c508eaa4fd7eb1c880cd27e3',
      txVersion: 3,
      electrumRequiredProtocol: 1.4,
      electrumServers: [
        'wss://electrum.peercoinexplorer.net:50004',
        'wss://allingas.peercoinexplorer.net:50004',
      ],
      marismaServers: [
        ('marisma.ppc.lol', 8443),
      ],
    ),
    'peercoinTestnet': Coin(
      name: 'peercoinTestnet',
      displayName: 'Peercoin Testnet',
      uriCode: 'peercoin',
      letterCode: 'tPPC',
      iconPath: 'assets/icon/ppc-icon-48-grey.png',
      iconPathTransparent: 'assets/icon/ppc-icon-48-grey.png',
      networkType: Network.testnet,
      opreturnSize: 256,
      fixedFee: true,
      fractions: 6,
      minimumTxValue: 10000,
      fixedFeePerKb: 0.01,
      explorerUrl: 'https://tblockbook.peercoin.net',
      genesisHash:
          '00000001f757bb737f6596503e17cd17b0658ce630cc727c0cca81aec47c9f06',
      txVersion: 3,
      electrumRequiredProtocol: 1.4,
      electrumServers: [
        'wss://testnet-electrum.peercoinexplorer.net:50009',
        'wss://allingas.peercoinexplorer.net:50009',
      ],
      marismaServers: [
        ('test-marisma.ppc.lol', 2096),
      ],
    ),
    'nusacoin': Coin(
      name: 'nusacoin',
      displayName: 'Nusacoin',
      uriCode: 'nusacoin',
      letterCode: 'NUX',
      // TODO(GreenWallet Phase 4): replace with NUX icons (Emerald Deep).
      iconPath: 'assets/icon/ppc-icon-48.png',
      iconPathTransparent: 'assets/icon/ppc-icon-white-48.png',
      networkType: Network.nusacoin,
      opreturnSize: 80,
      fractions: 8,
      // Dust policy: 546 nusan, mirroring the node's dust relay threshold
      // for P2PKH (NUX uses Bitcoin-identical DUST_RELAY_TX_FEE=3000).
      minimumTxValue: 546,
      fixedFee: true,
      fixedFeePerKb: 0.01,
      explorerUrl: 'https://explorer.taobot.org',
      genesisHash:
          '0000017123d6f996589bc2e58bb5502218012ac7f527ab599a3be84c1951c669',
      txVersion: 2,
      electrumRequiredProtocol: 1.4,
      electrumServers: [
        'tcp://$nusacoinElectrumHost:50009',
      ],
      marismaServers: [],
    ),
    'nusacoinTestnet': Coin(
      name: 'nusacoinTestnet',
      displayName: 'Nusacoin Testnet',
      uriCode: 'nusacoin',
      letterCode: 'tNUX',
      // TODO(GreenWallet Phase 4): replace with NUX testnet icons.
      iconPath: 'assets/icon/ppc-icon-48-grey.png',
      iconPathTransparent: 'assets/icon/ppc-icon-48-grey.png',
      networkType: Network.nusacoinTestnet,
      opreturnSize: 80,
      fractions: 8,
      minimumTxValue: 546,
      fixedFee: true,
      fixedFeePerKb: 0.01,
      explorerUrl: 'https://explorer.taobot.org',
      genesisHash:
          '0000017123d6f996589bc2e58bb5502218012ac7f527ab599a3be84c1951c669',
      txVersion: 2,
      electrumRequiredProtocol: 1.4,
      electrumServers: [
        'tcp://$nusacoinTestnetElectrumHost:60009',
      ],
      marismaServers: [],
    ),
  };

  static Map<String, Coin> get availableCoins {
    return _availableCoinList;
  }

  // ignore: non_constant_identifier_names
  static final Map<String, String> _ROASTIconPaths = {
    'peercoin': 'assets/icon/roast-icon-64.png',
    'peercoinTestnet': 'assets/icon/roast-icon-64-grey.png',
  };

  static String getROASTIconPath(String identifier) {
    final coin = identifier.split('_').first;
    return _ROASTIconPaths[coin]!;
  }

  static Coin getSpecificCoin(String identifier) {
    final coin = identifier.split('_').first;
    if (_availableCoinList.containsKey(coin)) {
      return _availableCoinList[coin]!;
    } else {
      throw Exception('Coin not found');
    }
  }

  static int getDecimalProduct({
    required String identifier,
  }) {
    return pow(
      10,
      getSpecificCoin(identifier).fractions,
    ).toInt();
  }
}

import 'dart:async';

import '../providers/connection_provider.dart';

enum BackendType { electrum, marisma }

abstract class DataSource {
  BackendConnectionState connectionState = BackendConnectionState.waiting;
  Map<String, List?> paperWalletUtxos = {};
  List openReplies = [];
  Map addresses = {};
  int latestBlock = 0;

  Future<bool> init(
    String walletName, {
    bool requestedFromWalletHome = false,
    bool fromConnectivityChangeOrLifeCycle = false,
  }) async {
    throw UnimplementedError();
  }

  Future<void> closeConnection([bool intentional = true]) async {}

  void subscribeToScriptHashes(Map scriptHashes) {}

  void requestPaperWalletUtxos(String hashId, String address) {}
  void broadcastTransaction(String txHash, String txId) {}
  void requestTxUpdate(String txId) {}

  /// Estimated fee rate in coins per kB for confirmation within [blocks].
  /// Returns null when the backend does not support fee estimation.
  Future<double?> estimateFeeRate({int blocks = 6}) async {
    return null;
  }

  Stream listenerNotifierStream() {
    throw UnimplementedError();
  }

  void notifyListeners() {}
}

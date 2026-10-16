import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:greenwallet/models/available_coins.dart';
import 'package:greenwallet/models/hive/adapters/client_config_hive_adapter.dart';
import 'package:greenwallet/models/hive/adapters/ec_compressed_public_key_hive_adapter.dart';
import 'package:greenwallet/models/hive/adapters/ec_private_key_hive_adapter.dart';
import 'package:greenwallet/models/hive/adapters/ec_public_key_hive_adapter.dart';
import 'package:greenwallet/models/hive/adapters/final_expirable_hive_adapter.dart';
import 'package:greenwallet/models/hive/adapters/frost_key_with_details_hive_adapter.dart';
import 'package:greenwallet/models/hive/adapters/signature_nonces_hive_adapter.dart';
import 'package:greenwallet/models/hive/adapters/signature_request_id_hive_adapter.dart';
import 'package:greenwallet/models/hive/adapters/signing_nonces_hive_adapter.dart';
import 'package:greenwallet/models/hive/roast_wallet.dart';
import 'package:coinlib_flutter/coinlib_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/hive/app_options.dart';
import '../models/hive/coin_wallet.dart';
import '../models/hive/pending_notifications.dart';
import '../models/hive/server.dart';
import '../models/hive/wallet_address.dart';
import '../models/hive/wallet_transaction.dart';
import '../models/hive/wallet_utxo.dart';
import 'app_localizations.dart';
import 'logger_wrapper.dart';
import 'notification.dart';

class BackgroundSync {
  @pragma('vm:entry-point')
  static void backgroundFetchHeadlessTask(HeadlessEvent task) async {
    var taskId = task.taskId;
    var isTimeout = task.timeout;
    if (isTimeout) {
      LoggerWrapper.logWarn(
        'BackgroundSync',
        'backgroundFetchHeadlessTask',
        'Headless task timed-out: $taskId',
      );
      BackgroundFetch.finish(taskId);
      return;
    }
    LoggerWrapper.logInfo(
      'BackgroundSync',
      'backgroundFetchHeadlessTask',
      'Headless event received.',
    );
    await BackgroundSync.executeSync();
    BackgroundFetch.finish(taskId);
  }

  static Future<void> init({
    required int notificationInterval,
    bool needsStart = false,
  }) async {
    Future<void> initPlatformState() async {
      var status = await BackgroundFetch.configure(
          BackgroundFetchConfig(
            minimumFetchInterval: notificationInterval,
            startOnBoot: true,
            stopOnTerminate: false,
            enableHeadless: Platform.isAndroid ? true : false,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.ANY,
          ), (String taskId) async {
        LoggerWrapper.logInfo(
          'BackgroundSync',
          'init',
          'Event received $taskId',
        );
        await BackgroundSync.executeSync();
        BackgroundFetch.finish(taskId);
      }, (String taskId) async {
        LoggerWrapper.logInfo(
          'BackgroundSync',
          'init',
          'TASK TIMEOUT taskId: $taskId',
        );
        BackgroundFetch.finish(taskId);
      });
      LoggerWrapper.logInfo(
        'BackgroundSync',
        'init',
        'configure success: $status',
      );
    }

    await initPlatformState();
    if (Platform.isAndroid) {
      await BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
    }
    if (needsStart == true) {
      await BackgroundFetch.start();
    }
  }

  static Future<void> executeSync({bool fromScan = false}) async {
    if (kIsWeb) return;

    //this static method can't access the providers we already have so we have to re-invent some things here...
    Uint8List encryptionKey;
    var secureStorage = const FlutterSecureStorage();
    var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    //check if key exists or return
    if (await secureStorage.containsKey(key: 'key')) {
      encryptionKey =
          base64Url.decode((await secureStorage.read(key: 'key') as String));
    } else {
      return;
    }

    //init hive - sadly we have to register all of them here
    if (!Hive.isAdapterRegistered(1)) {
      await Hive.initFlutter();
      Hive.registerAdapter(CoinWalletAdapter());
      Hive.registerAdapter(WalletTransactionAdapter());
      Hive.registerAdapter(WalletAddressAdapter());
      Hive.registerAdapter(WalletUtxoAdapter());
      Hive.registerAdapter(AppOptionsStoreAdapter());
      Hive.registerAdapter(ServerAdapter());
      Hive.registerAdapter(PendingNotificationAdapter());
      Hive.registerAdapter(ROASTWalletAdapter());
      Hive.registerAdapter(HiveROASTClientConfigAdapter());
      Hive.registerAdapter(HiveECPrivateKeyAdapter());
      Hive.registerAdapter(HiveECPublicKeyAdapter());
      Hive.registerAdapter(HiveECCompressedPublicKeyAdapter());
      Hive.registerAdapter(HiveFrostKeyWithDetailsAdapter());
      Hive.registerAdapter(HiveSignaturesRequestIdAdapter());
      Hive.registerAdapter(HiveSignaturesNoncesAdapter());
      Hive.registerAdapter(HiveSigingNoncesAdapter());
      Hive.registerAdapter(HiveFinalExpirableAdapter());
    }

    //open wallet box
    var walletBox = await Hive.openBox<CoinWallet>(
      'wallets',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    //open settings box
    var optionsBox = await Hive.openBox(
      'optionsBox',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    AppOptionsStore appOptions = optionsBox.get('appOptions');

    //check pending notifications
    var sharedPrefs = await SharedPreferences.getInstance();

    //init app delegate
    await AppLocalizations.delegate.load(
      Locale(sharedPrefs.getString('language_code') ?? 'und'),
    );

    //loop through wallets
    for (var wallet in walletBox.values) {
      if (appOptions.notificationActiveWallets.contains(wallet.name)) {
        //collect addresses to check: watched ones, funded ones,
        //and the last (unused/change) address
        final addressesToQuery = <String>[];
        final utxos = wallet.utxos;
        final pendingAddresses = wallet.pendingTransactionNotifications
            .map((e) => e.address)
            .toSet();

        for (var walletAddress in wallet.addresses) {
          final utxoRes = utxos.firstWhereOrNull(
            (element) => element.address == walletAddress.address,
          );
          if (walletAddress.isOurs == true) {
            if (walletAddress.isWatched == true ||
                utxoRes != null && utxoRes.value > 0 ||
                wallet.addresses.indexOf(walletAddress) ==
                    wallet.addresses.length - 1) {
              //skip addresses with an unconfirmed pending notification
              if (!pendingAddresses.contains(walletAddress.address)) {
                addressesToQuery.add(walletAddress.address);
              }
            }
          }
        }

        LoggerWrapper.logInfo(
          'BackgroundSync',
          'executeSync ${wallet.name}',
          'addressesToQuery $addressesToQuery',
        );

        //local balances from the last foreground sync
        final localBalances = <String, int>{};
        for (final utxo in utxos) {
          localBalances[utxo.address] =
              (localBalances[utxo.address] ?? 0) + utxo.value;
        }

        //remote balances from the wallet's own Electrum server
        final remoteBalances = await getBalancesFromElectrum(
          identifier: wallet.name,
          addresses: addressesToQuery,
          encryptionKey: encryptionKey,
        );

        var shouldNotify = false;

        LoggerWrapper.logInfo(
          'BackgroundSync',
          'executeSync ${wallet.name}',
          'result $remoteBalances',
        );

        remoteBalances.forEach((addr, remoteBalance) {
          final localBalance = localBalances[addr] ?? 0;
          if (remoteBalance > localBalance) {
            //new incoming funds since the last sync
            wallet.putPendingTransactionNotification(
              PendingNotification(
                address: addr,
                tx: remoteBalance,
              ),
            );
            shouldNotify = true;
          }
        });

        if (fromScan == true) {
          //foreground scan picked everything up; clear pendings
          wallet.clearPendingTransactionNotifications();
        }

        if (shouldNotify == true && fromScan == false) {
          await flutterLocalNotificationsPlugin.show(
            DateTime.now().millisecondsSinceEpoch ~/ 10000,
            AppLocalizations.instance.translate(
              'notification_title',
              {'walletTitle': wallet.title},
            ),
            AppLocalizations.instance.translate('notification_body'),
            LocalNotificationSettings.platformChannelSpecifics,
            payload: wallet.name,
          );
        }
      }
    }
  }

  /// Returns the total (confirmed + unconfirmed) balance in the coin's smallest
  /// unit for each address, queried from the wallet's own Electrum server via a
  /// single batched `blockchain.scripthash.get_balance` request.
  /// Returns an empty map when there is no usable server or the query fails,
  /// in which case the sync is silently skipped until the next run.
  static Future<Map<String, int>> getBalancesFromElectrum({
    required String identifier,
    required List<String> addresses,
    required Uint8List encryptionKey,
  }) async {
    final balances = <String, int>{};
    if (addresses.isEmpty) return balances;

    //pick the wallet's Electrum server (highest priority usable one),
    //so custom user-configured servers keep working
    String? serverAddress;
    try {
      final serverBox = await Hive.openBox<Server>(
        'serverBox-$identifier',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
      final servers = serverBox.values
          .where((s) => !s.hidden && s.connectable)
          .toList()
        ..sort((a, b) => a.priority.compareTo(b.priority));
      if (servers.isNotEmpty) serverAddress = servers.first.address;
      await serverBox.close();
    } catch (e) {
      LoggerWrapper.logWarn(
        'BackgroundSync',
        'getBalancesFromElectrum',
        'cannot open server box: $e',
      );
      return balances;
    }
    if (serverAddress == null) {
      LoggerWrapper.logInfo(
        'BackgroundSync',
        'getBalancesFromElectrum',
        'no usable Electrum server for $identifier',
      );
      return balances;
    }

    //parse tcp://host:port / ssl://host:port (same format as the foreground client)
    final isSsl = serverAddress.contains('ssl://');
    if (!isSsl && !serverAddress.contains('tcp://')) {
      LoggerWrapper.logWarn(
        'BackgroundSync',
        'getBalancesFromElectrum',
        'unsupported server protocol: $serverAddress',
      );
      return balances;
    }
    final parts = serverAddress.split(':');
    if (parts.length < 3) return balances;
    final host = parts[1].replaceAll('//', '');
    final port = int.tryParse(parts[2]);
    if (host.isEmpty || port == null) return balances;

    //derive scripthashes (same derivation as WalletProvider.getScriptHash)
    late final Network network;
    try {
      network = AvailableCoins.getSpecificCoin(identifier).networkType;
    } catch (e) {
      LoggerWrapper.logWarn(
        'BackgroundSync',
        'getBalancesFromElectrum',
        'unknown coin identifier: $identifier',
      );
      return balances;
    }
    final scripthashByAddress = <String, String>{};
    for (final address in addresses) {
      try {
        final script =
            Address.fromString(address, network).program.script.compiled;
        scripthashByAddress[address] =
            _reverseHex(sha256.convert(script).toString());
      } catch (e) {
        LoggerWrapper.logWarn(
          'BackgroundSync',
          'getBalancesFromElectrum',
          'cannot derive scripthash for $address: $e',
        );
      }
    }
    if (scripthashByAddress.isEmpty) return balances;

    //single batched JSON-RPC request: one round trip for all addresses
    final batch = <Map<String, dynamic>>[];
    final idToAddress = <int, String>{};
    var id = 0;
    for (final entry in scripthashByAddress.entries) {
      batch.add({
        'jsonrpc': '2.0',
        'id': id,
        'method': 'blockchain.scripthash.get_balance',
        'params': [entry.value],
      });
      idToAddress[id] = entry.key;
      id++;
    }

    Socket? socket;
    try {
      socket = isSsl
          ? await SecureSocket.connect(
              host,
              port,
              timeout: const Duration(seconds: 10),
            )
          : await Socket.connect(
              host,
              port,
              timeout: const Duration(seconds: 10),
            );
      socket.write('${jsonEncode(batch)}\n');
      await socket.flush();

      final responseLine = await socket
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first
          .timeout(const Duration(seconds: 15));
      final decoded = jsonDecode(responseLine);
      final responses = decoded is List ? decoded : [decoded];
      for (final r in responses) {
        final responseId = r['id'];
        final address = responseId is int ? idToAddress[responseId] : null;
        final res = r['result'];
        if (address != null && res is Map) {
          final confirmed = (res['confirmed'] as num?)?.toInt() ?? 0;
          final unconfirmed = (res['unconfirmed'] as num?)?.toInt() ?? 0;
          balances[address] = confirmed + unconfirmed;
        }
      }
    } catch (e) {
      LoggerWrapper.logWarn(
        'BackgroundSync',
        'getBalancesFromElectrum',
        'electrum query failed: $e',
      );
    } finally {
      try {
        await socket?.close();
      } catch (_) {}
    }
    return balances;
  }

  /// Reverses a hex string byte-wise (big-endian -> little-endian),
  /// as required for Electrum scripthashes.
  static String _reverseHex(String hex) {
    final out = StringBuffer();
    for (var i = hex.length - 2; i >= 0; i -= 2) {
      out.write(hex.substring(i, i + 2));
    }
    return out.toString();
  }
}

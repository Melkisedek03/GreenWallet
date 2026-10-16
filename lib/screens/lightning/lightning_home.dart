import 'dart:async';

import 'package:flutter/material.dart';

import '../../data_sources/lnbits_backend.dart';
import '../../tools/app_localizations.dart';
import '../../tools/app_routes.dart';
import '../../tools/lnbits_storage.dart';
import '../../tools/logger_wrapper.dart';
import '../../widgets/loading_indicator.dart';
import 'lightning_history.dart';
import 'lightning_receive.dart';
import 'lightning_send.dart';
import 'lightning_setup.dart';

enum LightningTab { receive, send, history }

/// Main Lightning screen (testnet).
///
/// Shows the setup/import flow when no LNbits keys are stored, otherwise the
/// wallet UI with receive / send / history tabs. Listens on the LNbits
/// WebSocket for realtime balance updates.
class LightningHomeScreen extends StatefulWidget {
  const LightningHomeScreen({super.key});

  @override
  State<LightningHomeScreen> createState() => _LightningHomeScreenState();
}

class _LightningHomeScreenState extends State<LightningHomeScreen> {
  bool _initial = true;
  bool _hasKeys = false;
  bool _loadingBalance = false;
  int? _balanceNusan;
  String? _error;
  LightningTab _tab = LightningTab.receive;
  LnbitsBackend? _backend;
  StreamSubscription<dynamic>? _wsSubscription;

  @override
  void didChangeDependencies() {
    if (_initial) {
      _init();
      setState(() => _initial = false);
    }
    super.didChangeDependencies();
  }

  Future<void> _init() async {
    await _wsSubscription?.cancel();
    _wsSubscription = null;
    final keys = await LnbitsStorage.readKeys();
    if (keys == null) {
      setState(() => _hasKeys = false);
      return;
    }
    final baseUrl = await LnbitsStorage.getBaseUrl();
    _backend = LnbitsBackend(
      baseUrl: baseUrl,
      inkey: keys.inkey,
      adminkey: keys.adminkey,
    );
    setState(() => _hasKeys = true);
    await _refreshBalance();
    _subscribe();
  }

  void _subscribe() {
    _wsSubscription?.cancel();
    if (_backend == null) return;
    try {
      _wsSubscription = _backend!.listenPayments(() {
        if (mounted) _refreshBalance();
      });
    } catch (e) {
      LoggerWrapper.logError('LightningHome', 'ws', 'subscribe failed: $e');
    }
  }

  Future<void> _refreshBalance() async {
    if (_backend == null) return;
    setState(() {
      _loadingBalance = true;
      _error = null;
    });
    try {
      final balance = await _backend!.getBalanceNusan();
      if (!mounted) return;
      setState(() {
        _balanceNusan = balance;
        _loadingBalance = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingBalance = false;
      });
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initial) {
      return Scaffold(
        appBar: AppBar(
          title:
              Text(AppLocalizations.instance.translate('lightning_title')),
        ),
        body: const Center(child: LoadingIndicator()),
      );
    }
    if (!_hasKeys || _backend == null) {
      return const LightningSetupScreen();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.instance.translate('lightning_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadingBalance ? null : _refreshBalance,
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () async {
              await Navigator.pushNamed(context, Routes.lightningSettings);
              // base URL or keys may have changed
              await _init();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_backend!.isSecure) _httpWarningBanner(context),
          _balanceHeader(context),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(child: _tabBody()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab.index,
        onTap: (i) => setState(() => _tab = LightningTab.values[i]),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.download_rounded),
            label: AppLocalizations.instance
                .translate('lightning_tab_receive'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.upload_rounded),
            label:
                AppLocalizations.instance.translate('lightning_tab_send'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_rounded),
            label: AppLocalizations.instance
                .translate('lightning_tab_history'),
          ),
        ],
      ),
    );
  }

  Widget _httpWarningBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade800,
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.instance
                  .translate('lightning_http_warning'),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            AppLocalizations.instance.translate('lightning_balance'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          _loadingBalance
              ? const LoadingIndicator()
              : Text(
                  _balanceNusan == null
                      ? '—'
                      : AppLocalizations.instance.translate(
                          'lightning_balance_value',
                          {'amount': '$_balanceNusan'},
                        ),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
        ],
      ),
    );
  }

  Widget _tabBody() {
    final backend = _backend!;
    switch (_tab) {
      case LightningTab.receive:
        return LightningReceiveTab(backend: backend);
      case LightningTab.send:
        return LightningSendTab(
          backend: backend,
          balanceNusan: _balanceNusan,
          onPaid: _refreshBalance,
        );
      case LightningTab.history:
        return LightningHistoryTab(backend: backend);
    }
  }
}

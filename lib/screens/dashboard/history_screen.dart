import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/available_coins.dart';
import '../../models/hive/coin_wallet.dart';
import '../../models/hive/wallet_transaction.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../tools/app_localizations.dart';
import '../../tools/gw_design.dart';

/// Fase C history screen: full transaction list across all wallets,
/// styled per the dashboard design language.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  List<WalletTransaction> _allTransactions(
      WalletProvider walletProvider, AppSettingsProvider appSettings,) {
    final all = <WalletTransaction>[];
    final order = appSettings.walletOrder;
    final wallets = walletProvider.availableWalletValues.toList()
      ..sort((a, b) => order.indexOf(a.name).compareTo(order.indexOf(b.name)));
    for (final CoinWallet wallet in wallets) {
      if (wallet.hidden) continue;
      all.addAll(wallet.transactions);
    }
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all;
  }

  String _formatAmount(int value, int fractions) {
    return GwDesign.formatBalance(value.abs(), fractions);
  }

  String _timeLabel(BuildContext context, int timestamp) {
    if (timestamp <= 0) {
      return AppLocalizations.instance.translate('history_pending');
    }
    return GwDesign.txTimeLabel(context, timestamp);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.instance.translate;
    final walletProvider =
        Provider.of<WalletProvider>(context, listen: false);
    final appSettings =
        Provider.of<AppSettingsProvider>(context, listen: false);
    final txs = _allTransactions(walletProvider, appSettings);

    return Scaffold(
      backgroundColor: GwDesign.background,
      appBar: AppBar(
        backgroundColor: GwDesign.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t('dashboard_nav_history'), style: GwDesign.appBarTitle),
      ),
      body: txs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: GwDesign.mutedText,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(t('history_empty'), style: GwDesign.bodyText),
                ],
              ),
            )
          : ListView.separated(
              padding:
                  const EdgeInsets.all(GwDesign.spacingScreen),
              itemCount: txs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final tx = txs[index];
                final isReceived = tx.direction == 'received';
                // Find wallet for fractions (fallback 8).
                int fractions = 8;
                String code = 'NUX';
                try {
                  final wallet = walletProvider.availableWalletValues
                      .firstWhere((w) =>
                          w.transactions.any((v) => v.txid == tx.txid),);
                  final coin =
                      AvailableCoins.getSpecificCoin(wallet.name);
                  fractions = coin.fractions;
                  code = wallet.letterCode;
                } catch (_) {}
                return Container(
                  padding: const EdgeInsets.all(GwDesign.spacingCard),
                  decoration: BoxDecoration(
                    color: GwDesign.cardBackground,
                    borderRadius:
                        BorderRadius.circular(GwDesign.radiusCard),
                    border: Border.all(
                        color: GwDesign.cardBorder.withValues(alpha: 0.4),),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isReceived
                              ? GwDesign.mintAccent.withValues(alpha: 0.2)
                              : GwDesign.mutedText.withValues(alpha: 0.2),
                        ),
                        child: Icon(
                          isReceived
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: isReceived
                              ? GwDesign.mintAccent
                              : GwDesign.mutedText,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isReceived
                                  ? t('history_received')
                                  : t('history_sent'),
                              style: GwDesign.txTitle,
                            ),
                            Text(
                              GwDesign.shortenAddress(tx.address),
                              style: GwDesign.mutedSmall,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isReceived ? '+' : '-'}${_formatAmount(tx.value, fractions)} $code',
                            style: isReceived
                                ? GwDesign.txAmountPositive
                                : GwDesign.txAmountNegative,
                          ),
                          Text(
                            _timeLabel(context, tx.timestamp),
                            style: GwDesign.mutedSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

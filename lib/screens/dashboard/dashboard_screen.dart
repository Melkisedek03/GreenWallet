import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/available_coins.dart';
import '../../models/hive/coin_wallet.dart';
import '../../models/hive/wallet_transaction.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../tools/app_localizations.dart';
import '../../tools/app_routes.dart';
import '../../tools/gw_design.dart';

/// Fase A dashboard: mockup-style home screen.
///
/// Shows the first active wallet's balance in a hero card, quick actions
/// (Send/Receive wired to the existing wallet flows; Buy/Swap disabled with
/// a "Coming soon" notice), recent transactions, and a bottom nav where only
/// Home is active for now.
class DashboardScreen extends StatefulWidget {
  final String walletToOpenDirectly;

  const DashboardScreen({
    super.key,
    this.walletToOpenDirectly = '',
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _initial = true;
  List<CoinWallet> _wallets = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initial) {
      _initial = false;
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final appSettings =
          Provider.of<AppSettingsProvider>(context, listen: false);
      final values = walletProvider.availableWalletValues.toList();
      final order = appSettings.walletOrder;
      values.sort(
        (a, b) => order.indexOf(a.name).compareTo(order.indexOf(b.name)),
      );
      final wallets = values.where((w) => !w.hidden).toList();
      setState(() {
        _wallets = wallets;
      });
      // Handle cold-start from a notification payload: open the wallet
      // directly, preserving the old WalletListScreen behavior.
      if (widget.walletToOpenDirectly.isNotEmpty) {
        final target = wallets.firstWhereOrNull(
          (w) => w.name == widget.walletToOpenDirectly,
        );
        if (target != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.pushNamed(
              context,
              Routes.standardAndWatchOnlyWalletHome,
              arguments: {'wallet': target},
            );
          });
        }
      }
    }
  }

  CoinWallet? get _activeWallet => _wallets.isNotEmpty ? _wallets.first : null;

  String _greeting() {
    final hour = DateTime.now().hour;
    final t = AppLocalizations.instance.translate;
    if (hour < 12) return t('dashboard_greeting_morning');
    if (hour < 18) return t('dashboard_greeting_afternoon');
    return t('dashboard_greeting_evening');
  }

  void _openWalletHome(String tabName) {
    final wallet = _activeWallet;
    if (wallet == null) return;
    Navigator.pushNamed(
      context,
      Routes.standardAndWatchOnlyWalletHome,
      arguments: {
        'wallet': wallet,
        'initialTab': tabName,
      },
    );
  }

  void _comingSoon() {
    final t = AppLocalizations.instance.translate;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t('dashboard_coming_soon'))),
    );
  }

  void _openWalletList() {
    Navigator.pushNamed(context, Routes.walletList);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.instance.translate;
    final wallet = _activeWallet;

    return Scaffold(
      backgroundColor: GwDesign.background,
      body: SafeArea(
        child: wallet == null
            ? _buildEmptyState(t('dashboard_no_wallets'))
            : RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(GwDesign.spacingPage),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(wallet),
                      const SizedBox(height: GwDesign.spacingSection),
                      _buildHeroCard(wallet),
                      const SizedBox(height: GwDesign.spacingSection),
                      _buildQuickActions(),
                      const SizedBox(height: GwDesign.spacingSection),
                      _buildRecentTransactionsHeader(),
                      const SizedBox(height: 8),
                      _buildRecentTransactions(wallet),
                      const SizedBox(height: 90), // room for bottom nav
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: wallet == null
          ? FloatingActionButton(
              onPressed: _openWalletList,
              backgroundColor: GwDesign.positive,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GwDesign.spacingPage),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: GwDesign.bottomNavInactive,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GwDesign.emptyState,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openWalletList,
              style: ElevatedButton.styleFrom(
                backgroundColor: GwDesign.positive,
                foregroundColor: Colors.white,
              ),
              child: Text(
                AppLocalizations.instance.translate(
                  'dashboard_manage_wallets',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CoinWallet wallet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            '${_greeting()},\n${wallet.name}',
            style: GwDesign.greeting,
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: _openWalletList,
          borderRadius: BorderRadius.circular(GwDesign.radiusPill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: GwDesign.cardBorder),
              borderRadius: BorderRadius.circular(GwDesign.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    wallet.name,
                    style: GwDesign.walletPillLabel,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: GwDesign.positive,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(CoinWallet wallet) {
    final t = AppLocalizations.instance.translate;
    final balance = GwDesign.formatBalance(
      wallet.balance,
      AvailableCoins.getSpecificCoin(wallet.name).fractions,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GwDesign.spacingCard + 8),
      decoration: BoxDecoration(
        gradient: GwDesign.heroCardGradient,
        borderRadius: BorderRadius.circular(GwDesign.radiusCard),
        border: Border.all(color: GwDesign.cardBorder.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.7)),
                ),
                child: const Center(
                  child: Text(
                    'N',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                t('dashboard_balance_label', {'code': wallet.letterCode}),
                style: GwDesign.heroLabel,
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: balance, style: GwDesign.heroBalance),
                TextSpan(
                text: ' ${wallet.letterCode}',
                style: GwDesign.heroBalanceUnit,
              ),
              ],
            ),
          ),
          // Note: no fiat conversion — PriceTicker has no NUX feed yet.
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final t = AppLocalizations.instance.translate;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildQuickAction(
          icon: Icons.send_rounded,
          label: t('dashboard_action_send'),
          onTap: () => _openWalletHome('send'),
        ),
        _buildQuickAction(
          icon: Icons.qr_code_2_rounded,
          label: t('dashboard_action_receive'),
          onTap: () => _openWalletHome('receive'),
        ),
        _buildQuickAction(
          icon: Icons.credit_card_rounded,
          label: t('dashboard_action_buy'),
          enabled: false,
          onTap: _comingSoon,
        ),
        _buildQuickAction(
          icon: Icons.swap_horiz_rounded,
          label: t('dashboard_action_swap'),
          enabled: false,
          onTap: _comingSoon,
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final color = enabled ? GwDesign.actionIcon : GwDesign.actionDisabled;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GwDesign.actionButtonFill,
              border: Border.all(
                color: enabled
                    ? GwDesign.actionButtonBorder
                    : GwDesign.actionDisabled,
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: GwDesign.actionLabel),
      ],
    );
  }

  Widget _buildRecentTransactionsHeader() {
    final t = AppLocalizations.instance.translate;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(t('dashboard_recent_transactions'), style: GwDesign.sectionTitle),
        InkWell(
          onTap: () => _openWalletHome('transactions'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t('dashboard_see_all'), style: GwDesign.seeAll),
              Icon(
                Icons.chevron_right_rounded,
                color: GwDesign.positive,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(CoinWallet wallet) {
    final t = AppLocalizations.instance.translate;
    final txs = wallet.transactions.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recent = txs.take(4).toList();

    if (recent.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            t('dashboard_no_transactions'),
            style: GwDesign.emptyState,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < recent.length; i++) ...[
          _buildTransactionRow(recent[i], wallet),
          if (i < recent.length - 1)
            Divider(color: GwDesign.divider, height: 1),
        ],
      ],
    );
  }

  Widget _buildTransactionRow(WalletTransaction tx, CoinWallet wallet) {
    final t = AppLocalizations.instance.translate;
    final isReceived = tx.direction == 'in';
    final amount = GwDesign.formatBalance(
      tx.value.abs(),
      AvailableCoins.getSpecificCoin(wallet.name).fractions,
    );
    final sign = isReceived ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isReceived ? GwDesign.positive : GwDesign.actionButtonFill,
              border:
                  isReceived ? null : Border.all(color: GwDesign.cardBorder),
            ),
            child: Icon(
              isReceived
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isReceived ? GwDesign.background : GwDesign.positive,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReceived
                      ? t('dashboard_tx_received', {'code': wallet.letterCode})
                      : t('dashboard_tx_sent', {'code': wallet.letterCode}),
                  style: GwDesign.txTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  isReceived
                      ? '${t('dashboard_tx_from')} ${GwDesign.shortenAddress(tx.address)}'
                      : '${t('dashboard_tx_to')} ${GwDesign.shortenAddress(tx.address)}',
                  style: GwDesign.txSubtitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign$amount ${wallet.letterCode}',
                style: isReceived
                    ? GwDesign.txAmountPositive
                    : GwDesign.txAmountNegative,
              ),
              const SizedBox(height: 2),
              Text(
                GwDesign.txTimeLabel(context, tx.timestamp),
                style: GwDesign.txTime,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final t = AppLocalizations.instance.translate;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: GwDesign.bottomNavBackground,
        borderRadius: BorderRadius.circular(GwDesign.radiusBottomNav),
        border: Border.all(color: GwDesign.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home_rounded,
            label: t('dashboard_nav_home'),
            active: true,
            onTap: () {},
          ),
          _buildNavItem(
            icon: Icons.bar_chart_rounded,
            label: t('dashboard_nav_markets'),
            active: false,
            onTap: _comingSoon,
          ),
          _buildNavItem(
            icon: Icons.history_rounded,
            label: t('dashboard_nav_history'),
            active: false,
            onTap: () => _openWalletHome('transactions'),
          ),
          _buildNavItem(
            icon: Icons.person_rounded,
            label: t('dashboard_nav_profile'),
            active: false,
            onTap: _comingSoon,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final color = active ? GwDesign.positive : GwDesign.bottomNavInactive;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GwDesign.radiusBottomNavItem),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: active
            ? BoxDecoration(
                border: Border.all(color: GwDesign.cardBorder),
                borderRadius:
                    BorderRadius.circular(GwDesign.radiusBottomNavItem),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 2),
            Text(label, style: GwDesign.bottomNavLabel.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

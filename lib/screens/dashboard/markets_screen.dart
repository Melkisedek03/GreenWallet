import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../tools/app_localizations.dart';
import '../../tools/gw_design.dart';
import '../../tools/logger_wrapper.dart';

/// Markets screen: NUX/USDT price stats from the Qutrade public API.
///
/// Uses only the public (no-auth) endpoint:
/// `https://qutrade.io/api/v2/spot_markets?pair=NUX_USDT&field=last,trend,base_volume,volume_usd,ask,bid`
/// On API failure the last successfully fetched data is kept on screen
/// with an error notice; a retry button is offered.
class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketData {
  final double last;
  final double trend;
  final double baseVolume;
  final double volumeUsd;
  final double ask;
  final double bid;
  final DateTime fetchedAt;

  const _MarketData({
    required this.last,
    required this.trend,
    required this.baseVolume,
    required this.volumeUsd,
    required this.ask,
    required this.bid,
    required this.fetchedAt,
  });
}

class _MarketsScreenState extends State<MarketsScreen> {
  static const String _apiUrl =
      'https://qutrade.io/api/v2/spot_markets'
      '?pair=NUX_USDT&field=last,trend,base_volume,volume_usd,ask,bid';

  _MarketData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['result'] != 'success') {
        throw Exception(body['message']?.toString() ?? 'API error');
      }
      final payload = (body['payload'] as Map<String, dynamic>?)?['NUX_USDT']
          as Map<String, dynamic>?;
      if (payload == null) {
        throw Exception('NUX_USDT pair not found');
      }
      double num(String key) =>
          double.tryParse(payload[key]?.toString() ?? '') ?? 0.0;
      setState(() {
        _data = _MarketData(
          last: num('last'),
          trend: num('trend'),
          baseVolume: num('base_volume'),
          volumeUsd: num('volume_usd'),
          ask: num('ask'),
          bid: num('bid'),
          fetchedAt: DateTime.now(),
        );
        _loading = false;
      });
    } catch (e) {
      LoggerWrapper.logInfo('MarketsScreen', '_fetch', 'Fetch failed: $e');
      setState(() {
        _loading = false;
        // Keep previously fetched data on screen; only flag the error.
        if (_data == null) {
          _error = e.toString();
        }
      });
      if (_data != null && mounted) {
        final t = AppLocalizations.instance.translate;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('markets_refresh_failed'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.instance.translate;
    return Scaffold(
      backgroundColor: GwDesign.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetch,
          color: GwDesign.positive,
          backgroundColor: GwDesign.bottomNavBackground,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(GwDesign.spacingPage),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(t),
                const SizedBox(height: GwDesign.spacingSection),
                if (_loading && _data == null)
                  _buildLoading()
                else if (_error != null && _data == null)
                  _buildError(t)
                else ...[
                  _buildPriceCard(t),
                  const SizedBox(height: GwDesign.spacingSection),
                  _buildStatsGrid(t),
                  const SizedBox(height: 16),
                  _buildFooter(t),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TranslateFunction t) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: GwDesign.actionButtonFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GwDesign.cardBorder),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFFEAF4EF),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          t('dashboard_nav_markets'),
          style: GwDesign.greeting.copyWith(fontSize: 26),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: CircularProgressIndicator(color: Color(0xFF2FBF8F)),
      ),
    );
  }

  Widget _buildError(TranslateFunction t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: GwDesign.bottomNavInactive,
            ),
            const SizedBox(height: 16),
            Text(
              t('markets_load_failed'),
              style: GwDesign.emptyState,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetch,
              style: ElevatedButton.styleFrom(
                backgroundColor: GwDesign.positive,
                foregroundColor: Colors.white,
              ),
              child: Text(t('markets_retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(TranslateFunction t) {
    final data = _data!;
    final trendUp = data.trend >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GwDesign.spacingCard + 4),
      decoration: BoxDecoration(
        gradient: GwDesign.heroCardGradient,
        borderRadius: BorderRadius.circular(GwDesign.radiusCard),
        border: Border.all(color: GwDesign.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'N',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('NUX / USDT', style: GwDesign.heroLabel),
              const Spacer(),
              Text(
                'Qutrade',
                style: GwDesign.heroFiat.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '\$${_formatPrice(data.last)}',
            style: GwDesign.heroBalance,
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: trendUp
                  ? const Color(0xFF2FBF8F).withValues(alpha: 0.2)
                  : const Color(0xFFA8201A).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(GwDesign.radiusPill),
            ),
            child: Text(
              '${trendUp ? '+' : ''}${data.trend.toStringAsFixed(2)}% 24h',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: trendUp
                    ? const Color(0xFF2FBF8F)
                    : const Color(0xFFE57373),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(TranslateFunction t) {
    final data = _data!;
    final spread = data.ask > 0 && data.bid > 0
        ? ((data.ask - data.bid) / data.bid * 100)
        : 0.0;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatTile(
          label: t('markets_volume_24h'),
          value: '${_formatCompact(data.baseVolume)} NUX',
        ),
        _buildStatTile(
          label: t('markets_volume_usd'),
          value: '\$${_formatCompact(data.volumeUsd)}',
        ),
        _buildStatTile(
          label: t('markets_bid'),
          value: '\$${_formatPrice(data.bid)}',
        ),
        _buildStatTile(
          label: t('markets_ask'),
          value: '\$${_formatPrice(data.ask)}',
        ),
        _buildStatTile(
          label: t('markets_spread'),
          value: '${spread.toStringAsFixed(2)}%',
        ),
        _buildStatTile(
          label: t('markets_last_updated'),
          value: _formatTime(data.fetchedAt),
        ),
      ],
    );
  }

  Widget _buildStatTile({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GwDesign.actionButtonFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GwDesign.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GwDesign.heroFiat.copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFFEAF4EF),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(TranslateFunction t) {
    return Center(
      child: Text(
        t('markets_disclaimer'),
        style: GwDesign.heroFiat.copyWith(fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatPrice(double v) {
    if (v == 0) return '--';
    // NUX trades at sub-cent prices; show enough decimals.
    if (v < 0.01) return v.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    if (v < 1) return v.toStringAsFixed(4);
    return v.toStringAsFixed(2);
  }

  String _formatCompact(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(v < 10 ? 2 : 0);
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Matches the signature of AppLocalizations.translate for helper use.
typedef TranslateFunction = String Function(
  String key, [
  Map<String, String?>? arguments,
]);

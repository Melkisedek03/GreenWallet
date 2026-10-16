import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data_sources/lnbits_backend.dart';
import '../../models/lnbits_payment.dart';
import '../../tools/app_localizations.dart';
import '../../widgets/loading_indicator.dart';

/// History tab: list of LNbits payments, newest first.
class LightningHistoryTab extends StatefulWidget {
  final LnbitsBackend backend;

  const LightningHistoryTab({super.key, required this.backend});

  @override
  State<LightningHistoryTab> createState() => _LightningHistoryTabState();
}

class _LightningHistoryTabState extends State<LightningHistoryTab> {
  bool _initial = true;
  bool _loading = false;
  String? _error;
  List<LnbitsPayment> _payments = [];

  @override
  void didChangeDependencies() {
    if (_initial) {
      _load();
      setState(() => _initial = false);
    }
    super.didChangeDependencies();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payments = await widget.backend.getPayments();
      if (!mounted) return;
      setState(() {
        _payments = payments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _payments.isEmpty) {
      return const Center(child: LoadingIndicator());
    }
    if (_error != null && _payments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                child: Text(AppLocalizations.instance
                    .translate('lightning_history_retry')),
              ),
            ],
          ),
        ),
      );
    }
    if (_payments.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.instance.translate('lightning_history_empty'),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _payments.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) => _tile(context, _payments[i]),
      ),
    );
  }

  Widget _tile(BuildContext context, LnbitsPayment p) {
    final incoming = p.isIncoming;
    final color = p.isFailed
        ? Theme.of(context).colorScheme.error
        : incoming
            ? Colors.green
            : Theme.of(context).textTheme.bodyLarge?.color;
    return ListTile(
      leading: Icon(
        p.isPending
            ? Icons.hourglass_empty_rounded
            : incoming
                ? Icons.download_rounded
                : Icons.upload_rounded,
        color: color,
      ),
      title: Text(
        '${incoming ? '+' : '-'}${p.amountNusan.abs()} '
        '${AppLocalizations.instance.translate('lightning_unit_nusan')}',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.memo.isNotEmpty) Text(p.memo),
          Text(
            DateFormat.yMMMd().add_Hm().format(p.time.toLocal()),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (p.isPending)
            Text(
              AppLocalizations.instance
                  .translate('lightning_history_pending'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (p.isFailed)
            Text(
              AppLocalizations.instance.translate('lightning_history_failed'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}

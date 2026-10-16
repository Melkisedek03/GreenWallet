import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data_sources/lnbits_backend.dart';
import '../../tools/app_localizations.dart';
import '../../tools/app_routes.dart';
import '../../tools/lnbits_invoice.dart';
import '../../widgets/loading_indicator.dart';

/// Send tab: scan or paste a bolt11 invoice, review the decoded amount, pay.
///
/// The decoded amount is always shown and confirmed before paying because the
/// LNbits API performs no server-side amount check.
class LightningSendTab extends StatefulWidget {
  final LnbitsBackend backend;
  final int? balanceNusan;
  final Future<void> Function() onPaid;

  const LightningSendTab({
    super.key,
    required this.backend,
    required this.balanceNusan,
    required this.onPaid,
  });

  @override
  State<LightningSendTab> createState() => _LightningSendTabState();
}

class _LightningSendTabState extends State<LightningSendTab> {
  final _invoiceController = TextEditingController();
  LnbitsInvoice? _decoded;
  String? _error;
  bool _paying = false;

  @override
  void dispose() {
    _invoiceController.dispose();
    super.dispose();
  }

  Future<void> _scanInvoice() async {
    final result = await Navigator.of(context).pushNamed(
      Routes.qrScan,
      arguments:
          AppLocalizations.instance.translate('lightning_send_scan_title'),
    );
    if (result == null) return;
    _invoiceController.text = (result as String).trim();
    _decode();
  }

  void _decode() {
    setState(() {
      _error = null;
      _decoded = null;
    });
    final raw = _invoiceController.text.trim();
    if (raw.isEmpty) return;
    try {
      final invoice = LnbitsInvoice.decode(raw);
      if (!LnbitsInvoice.knownPrefixes
          .any((p) => invoice.bolt11.startsWith(p))) {
        throw const FormatException('unknown invoice prefix');
      }
      setState(() => _decoded = invoice);
    } catch (e) {
      setState(() {
        _error = AppLocalizations.instance
            .translate('lightning_send_decode_failed');
      });
    }
  }

  Future<void> _pay() async {
    final invoice = _decoded;
    if (invoice == null) return;
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      await widget.backend.payInvoice(invoice.bolt11);
      await widget.onPaid();
      if (!mounted) return;
      setState(() {
        _paying = false;
        _decoded = null;
        _invoiceController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.instance.translate('lightning_send_success'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = _decoded;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _invoiceController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.instance
                        .translate('lightning_send_invoice_label'),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => _decode(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                tooltip: AppLocalizations.instance
                    .translate('lightning_send_scan_title'),
                onPressed: _scanInvoice,
              ),
              IconButton(
                icon: const Icon(Icons.paste_rounded),
                tooltip: AppLocalizations.instance
                    .translate('lightning_send_paste'),
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  final text = data?.text?.trim() ?? '';
                  if (text.isEmpty) return;
                  _invoiceController.text = text;
                  _decode();
                },
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
          if (invoice != null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.instance
                          .translate('lightning_send_confirm_title'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _row(
                      context,
                      AppLocalizations.instance
                          .translate('lightning_send_amount_label'),
                      AppLocalizations.instance.translate(
                        'lightning_balance_value',
                        {'amount': '${invoice.amountNusan}'},
                      ),
                      emphasize: true,
                    ),
                    if (invoice.memo.isNotEmpty)
                      _row(
                        context,
                        AppLocalizations.instance
                            .translate('lightning_send_memo_label'),
                        invoice.memo,
                      ),
                    if (invoice.isExpired)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          AppLocalizations.instance.translate(
                              'lightning_send_expired'),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _paying
                ? const Center(child: LoadingIndicator())
                : ElevatedButton(
                    onPressed: (invoice.isExpired ||
                            invoice.amountNusan <= 0 ||
                            (widget.balanceNusan != null &&
                                invoice.amountNusan > widget.balanceNusan!))
                        ? null
                        : _pay,
                    child: Text(AppLocalizations.instance
                        .translate('lightning_send_pay_button')),
                  ),
            if (widget.balanceNusan != null &&
                invoice.amountNusan > widget.balanceNusan!)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  AppLocalizations.instance
                      .translate('lightning_send_insufficient'),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: emphasize
                  ? Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data_sources/lnbits_backend.dart';
import '../../tools/app_localizations.dart';
import '../../widgets/loading_indicator.dart';

/// Receive tab: create a bolt11 invoice and display it as QR + text.
class LightningReceiveTab extends StatefulWidget {
  final LnbitsBackend backend;

  const LightningReceiveTab({super.key, required this.backend});

  @override
  State<LightningReceiveTab> createState() => _LightningReceiveTabState();
}

class _LightningReceiveTabState extends State<LightningReceiveTab> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  bool _creating = false;
  String? _invoice;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _createInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _creating = true;
      _error = null;
      _invoice = null;
    });
    try {
      final invoice = await widget.backend.createInvoice(
        amountNusan: int.parse(_amountController.text.trim()),
        memo: _memoController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _invoice = invoice;
        _creating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _creating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: AppLocalizations.instance
                    .translate('lightning_receive_amount_label'),
                suffixText: AppLocalizations.instance
                    .translate('lightning_unit_nusan'),
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n <= 0) {
                  return AppLocalizations.instance
                      .translate('lightning_receive_amount_invalid');
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _memoController,
              decoration: InputDecoration(
                labelText: AppLocalizations.instance
                    .translate('lightning_receive_memo_label'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _creating
                ? const Center(child: LoadingIndicator())
                : ElevatedButton(
                    onPressed: _createInvoice,
                    child: Text(AppLocalizations.instance.translate(
                        'lightning_receive_create_button')),
                  ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
            if (_invoice != null) ...[
              const SizedBox(height: 24),
              Center(
                child: QrImageView(
                  data: _invoice!,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                _invoice!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _invoice!));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.instance
                          .translate('lightning_copied')),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: Text(AppLocalizations.instance
                    .translate('lightning_copy_invoice')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

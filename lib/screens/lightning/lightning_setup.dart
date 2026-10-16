import 'dart:convert';

import 'package:flutter/material.dart';

import '../../data_sources/lnbits_backend.dart';
import '../../tools/app_localizations.dart';
import '../../tools/app_routes.dart';
import '../../tools/lnbits_storage.dart';
import '../../widgets/loading_indicator.dart';

/// Import the LNbits wallet credentials.
///
/// Wallet creation is an admin operation — the app only imports the
/// inkey/adminkey pair the admin hands out (e.g. printed QR card).
/// The QR payload is JSON: {"inkey": "...", "adminkey": "..."}.
class LightningSetupScreen extends StatefulWidget {
  const LightningSetupScreen({super.key});

  @override
  State<LightningSetupScreen> createState() => _LightningSetupScreenState();
}

class _LightningSetupScreenState extends State<LightningSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inkeyController = TextEditingController();
  final _adminkeyController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _inkeyController.dispose();
    _adminkeyController.dispose();
    super.dispose();
  }

  Future<void> _scanQr() async {
    final result = await Navigator.of(context).pushNamed(
      Routes.qrScan,
      arguments:
          AppLocalizations.instance.translate('lightning_setup_scan_title'),
    );
    if (result == null) return;
    final raw = (result as String).trim();
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final inkey = (data['inkey'] as String?) ?? '';
      final adminkey = (data['adminkey'] as String?) ?? '';
      if (inkey.isEmpty) throw const FormatException('missing inkey');
      setState(() {
        _inkeyController.text = inkey;
        _adminkeyController.text = adminkey;
        _error = null;
      });
    } catch (_) {
      setState(() {
        _error = AppLocalizations.instance
            .translate('lightning_setup_qr_invalid');
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final baseUrl = await LnbitsStorage.getBaseUrl();
      final backend = LnbitsBackend(
        baseUrl: baseUrl,
        inkey: _inkeyController.text.trim(),
        adminkey: _adminkeyController.text.trim(),
      );
      // Verify the keys before storing them.
      await backend.getBalanceNusan();
      await LnbitsStorage.saveKeys(
        _inkeyController.text,
        _adminkeyController.text,
      );
      if (!mounted) return;
      // Return to the Lightning home, which will now load the wallet.
      Navigator.of(context).pushReplacementNamed(Routes.lightningHome);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.instance.translate(
          'lightning_setup_connection_failed',
          {'error': '$e'},
        );
        _saving = false;
      });
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(_error!), textAlign: TextAlign.center),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.instance.translate('lightning_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.instance
                    .translate('lightning_setup_heading'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.instance
                    .translate('lightning_setup_explainer'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saving ? null : _scanQr,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: Text(AppLocalizations.instance
                    .translate('lightning_setup_scan_button')),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _inkeyController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.instance
                      .translate('lightning_setup_inkey_label'),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? AppLocalizations.instance
                            .translate('lightning_field_required')
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adminkeyController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.instance
                      .translate('lightning_setup_adminkey_label'),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? AppLocalizations.instance
                            .translate('lightning_field_required')
                        : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              _saving
                  ? const Center(child: LoadingIndicator())
                  : ElevatedButton(
                      onPressed: _save,
                      child: Text(AppLocalizations.instance
                          .translate('lightning_setup_save_button')),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../data_sources/lnbits_backend.dart';
import '../../tools/app_localizations.dart';
import '../../tools/lnbits_storage.dart';
import '../../widgets/loading_indicator.dart';

/// Lightning settings: configurable base URL (never hardcoded) and wallet
/// removal. Shows a security warning while the URL is plain HTTP.
class LightningSettingsScreen extends StatefulWidget {
  const LightningSettingsScreen({super.key});

  @override
  State<LightningSettingsScreen> createState() =>
      _LightningSettingsScreenState();
}

class _LightningSettingsScreenState extends State<LightningSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  bool _initial = true;
  bool _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    if (_initial) {
      LnbitsStorage.getBaseUrl().then((url) {
        if (!mounted) return;
        setState(() {
          _urlController.text = url;
          _initial = false;
        });
      });
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  bool get _isHttp => !_urlController.text.trim().startsWith('https://');

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final url = _urlController.text.trim();
    await LnbitsStorage.setBaseUrl(url);
    // Verify the new URL works with the stored keys.
    try {
      final keys = await LnbitsStorage.readKeys();
      if (keys != null) {
        await LnbitsBackend(
          baseUrl: url,
          inkey: keys.inkey,
          adminkey: keys.adminkey,
        ).getBalanceNusan();
      }
      if (!mounted) return;
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _saving = false;
      });
    }
  }

  Future<void> _removeWallet() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.instance
            .translate('lightning_settings_remove_title')),
        content: Text(AppLocalizations.instance
            .translate('lightning_settings_remove_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.instance.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.instance.translate('lightning_remove')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await LnbitsStorage.clearKeys();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.instance
            .translate('lightning_settings_title')),
      ),
      body: _initial
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _urlController,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.instance.translate(
                            'lightning_settings_url_label'),
                        hintText: 'https://lnbits.example.com',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final url = (v ?? '').trim();
                        if (url.isEmpty) {
                          return AppLocalizations.instance
                              .translate('lightning_field_required');
                        }
                        if (!url.startsWith('http://') &&
                            !url.startsWith('https://')) {
                          return AppLocalizations.instance.translate(
                              'lightning_settings_url_scheme');
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_isHttp) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade800,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_rounded,
                                color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppLocalizations.instance.translate(
                                    'lightning_http_warning'),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _saving
                        ? const Center(child: LoadingIndicator())
                        : ElevatedButton(
                            onPressed: _save,
                            child: Text(AppLocalizations.instance
                                .translate('lightning_save')),
                          ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _removeWallet,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(AppLocalizations.instance.translate(
                          'lightning_settings_remove_button')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

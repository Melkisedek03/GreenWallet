import 'package:flutter/material.dart';

import '../../tools/app_localizations.dart';
import '../../tools/exchange_api_storage.dart';
import '../../tools/gw_design.dart';

/// Fase C: Qutrade API key management for private endpoints.
///
/// Stores the API key + secret in secure storage for future Buy/Swap
/// features. The secret is never displayed after saving and never logged.
class ExchangeApiScreen extends StatefulWidget {
  const ExchangeApiScreen({super.key});

  @override
  State<ExchangeApiScreen> createState() => _ExchangeApiScreenState();
}

class _ExchangeApiScreenState extends State<ExchangeApiScreen> {
  final _apiKeyController = TextEditingController();
  final _secretController = TextEditingController();
  bool _obscureSecret = true;
  bool _hasKeys = false;
  String _keyHint = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final hint = await ExchangeApiStorage.readKeyHint();
    if (!mounted) return;
    setState(() {
      _hasKeys = hint != null;
      _keyHint = hint?.hint ?? '';
    });
  }

  Future<void> _save() async {
    final apiKey = _apiKeyController.text.trim();
    final secret = _secretController.text.trim();
    if (apiKey.isEmpty || secret.isEmpty) return;
    setState(() => _saving = true);
    await ExchangeApiStorage.saveKeys(apiKey, secret);
    _apiKeyController.clear();
    _secretController.clear();
    await _loadState();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.instance.translate('exchange_api_saved'),
        ),
      ),
    );
  }

  Future<void> _clear() async {
    await ExchangeApiStorage.clearKeys();
    await _loadState();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.instance.translate('exchange_api_cleared'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.instance.translate;
    return Scaffold(
      backgroundColor: GwDesign.background,
      appBar: AppBar(
        backgroundColor: GwDesign.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t('profile_exchange_api'), style: GwDesign.appBarTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(GwDesign.spacingScreen),
        children: [
          Text(t('exchange_api_description'), style: GwDesign.bodyText),
          const SizedBox(height: 20),
          if (_hasKeys) ...[
            Container(
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
                  Icon(Icons.key_rounded,
                      color: GwDesign.mintAccent,),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t('exchange_api_configured'),
                            style: GwDesign.menuLabel,),
                        Text(_keyHint, style: GwDesign.mutedSmall),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _clear,
                    child: Text(t('exchange_api_clear')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(t('exchange_api_key_label'), style: GwDesign.sectionLabel),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: t('exchange_api_key_hint'),
              hintStyle: GwDesign.mutedSmall,
              filled: true,
              fillColor: GwDesign.cardBackground,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(GwDesign.radiusCard),
                borderSide: BorderSide(color: GwDesign.cardBorder),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(t('exchange_api_secret_label'), style: GwDesign.sectionLabel),
          const SizedBox(height: 8),
          TextField(
            controller: _secretController,
            obscureText: _obscureSecret,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: t('exchange_api_secret_hint'),
              hintStyle: GwDesign.mutedSmall,
              filled: true,
              fillColor: GwDesign.cardBackground,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(GwDesign.radiusCard),
                borderSide: BorderSide(color: GwDesign.cardBorder),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSecret
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: GwDesign.mutedText,
                ),
                onPressed: () =>
                    setState(() => _obscureSecret = !_obscureSecret),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: GwDesign.mintAccent,
                foregroundColor: GwDesign.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(GwDesign.radiusCard),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t('exchange_api_save'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16,),),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t('exchange_api_security_note'),
            style: GwDesign.mutedSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

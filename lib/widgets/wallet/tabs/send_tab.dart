import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:greenwallet/exceptions/exceptions.dart';
import 'package:greenwallet/models/buildresult.dart';
import 'package:greenwallet/tools/validators.dart';
import 'package:greenwallet/widgets/wallet/tabs/send_tab_management.dart';
import 'package:greenwallet/widgets/wallet/tabs/send_tab_navigator.dart';
import 'package:provider/provider.dart';

import '/../models/available_coins.dart';
import '/../models/coin.dart';
import '/../models/hive/coin_wallet.dart';
import '/../models/hive/wallet_address.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../providers/connection_provider.dart';
import '../../../screens/wallet/standard_and_watch_only_wallet_home.dart';
import '/../tools/app_localizations.dart';
import '/../tools/app_routes.dart';
import '/../tools/auth.dart';
import '/../tools/utf8_text_field.dart';
import '/../widgets/service_container.dart';
import '/../widgets/wallet/wallet_balance_header.dart';
import '../../../screens/wallet/transaction_confirmation.dart';
import '../../../tools/logger_wrapper.dart';
import '../../../tools/price_ticker.dart';
import '../../../tools/gw_design.dart';

class SendTab extends StatefulWidget {
  final Function changeTab;
  final String? address;
  final String? label;
  final BackendConnectionState connectionState;
  final CoinWallet wallet;
  const SendTab({
    required this.changeTab,
    this.address,
    this.label,
    required this.wallet,
    required this.connectionState,
    super.key,
  });

  @override
  State<SendTab> createState() => _SendTabState();
}

class _SendTabState extends State<SendTab> {
  final _formKey = GlobalKey<FormState>();
  final _addressKeyList = [GlobalKey<FormFieldState>()];
  final _amountKeyList = [GlobalKey<FormFieldState>()];
  final _labelKeyList = [GlobalKey<FormFieldState>()];
  final _opReturnKey = GlobalKey<FormFieldState>();
  final _addressControllerList = [TextEditingController()];
  final _amountControllerList = [TextEditingController()];
  final _labelControllerList = [TextEditingController()];
  final _opReturnController = TextEditingController();
  bool _initial = true;
  late Coin _availableCoin;
  late WalletProvider _walletProvider;
  late List<WalletAddress> _availableAddresses = [];
  bool _expertMode = false;
  late AppSettingsProvider _appSettings;
  late final int _decimalProduct;
  bool _fiatEnabled = false;
  bool _fiatInputEnabled = false;
  final Map<int, String> _amountInputHelperTextList = {};
  final Map<int, double> _requestedAmountInCoinsList = {};
  double _totalAmountRequestedInCoins = 0.0;
  double _coinValue = 0.0;
  int _numberOfRecipients = 1;
  int _currentAddressIndex = 0;

  /// Fee tier selected in the UI: 0 = Slow, 1 = Normal, 2 = Fast.
  /// Maps to [GwDesign.feeBlocksSlow/Normal/Fast] targets for
  /// blockchain.estimatefee. There was no fee-tier selector before;
  /// the fee was always estimated with the default target.
  int _feeTier = 1;

  @override
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.instance.translate;
    return Stack(
      children: [
        WalletBalanceHeader(widget.connectionState, widget.wallet),
        ListView(
          children: [
            SizedBox(
              height: widget.wallet.unconfirmedBalance > 0 ? 125 : 110,
            ),
            Container(
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BottomAppBarTheme.of(context).color!,
                    Theme.of(context).primaryColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Align(
              child: AppContainer(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Multi-recipient navigator (unchanged logic)
                      if (_numberOfRecipients > 1)
                        SendTabNavigator(
                          currentIndex: _currentAddressIndex + 1,
                          numberOfRecipients: _numberOfRecipients,
                          raiseNewindex: (int newIndex) => setState(
                            () {
                              if (triggerFormValidation()) {
                                _currentAddressIndex = newIndex - 1;
                              }
                            },
                          ),
                        ),
                      // Recipient section (mockup style)
                      _buildRecipientSection(t),
                      const SizedBox(height: 20),
                      // Label field (optional, mockup style)
                      _buildLabelField(t),
                      const SizedBox(height: 20),
                      // Amount section (mockup style)
                      _buildAmountSection(t),
                      const SizedBox(height: 20),
                      // Network fee pills (mockup style)
                      _buildFeeSection(t),
                      const SizedBox(height: 20),
                      // Summary card (mockup style)
                      _buildSummaryCard(t),
                      const SizedBox(height: 20),
                      // Primary send button (gradient, mockup style)
                      _buildSendButton(t),
                      const SizedBox(height: 12),
                      // Secondary actions
                      _buildSecondaryActions(t),
                      const SizedBox(height: 12),
                      // Expert mode toggle + OP_RETURN (unchanged logic)
                      _buildExpertSection(t),
                      // Address management (add/delete recipient)
                      SendTabAddressManagement(
                        onAdd: () {
                          if (_addNewAddress()) {
                            setState(
                              () {
                                _numberOfRecipients++;
                              },
                            );
                          }
                        },
                        onDelete: () {
                          _removeAddress(_currentAddressIndex);
                        },
                        numberOfRecipients: _numberOfRecipients,
                      ),
                      // Fiat switch (unchanged logic)
                      if (_fiatEnabled && _currentAddressIndex == 0)
                        SwitchListTile(
                          value: _fiatInputEnabled,
                          onChanged: (newState) => setState(
                            () {
                              _fiatInputEnabled = newState;
                              _amountControllerList[_currentAddressIndex].text =
                                  '';
                              _amountControllerList[_currentAddressIndex]
                                  .selection = TextSelection.fromPosition(
                                TextPosition(
                                  offset: _amountControllerList[
                                          _currentAddressIndex]
                                      .text
                                      .length,
                                ),
                              );
                              _amountControllerList.asMap().forEach(
                                (index, _) {
                                  _amountControllerList[index].text = '';
                                  _calcAmountInputHelperText(index);
                                },
                              );
                            },
                          ),
                          title: Text(
                            t('send_fiat_switch', {
                              'currency': _appSettings.selectedCurrency,
                            }),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Recipient address field in mockup style: mint "Recipient" label,
  /// rounded dark input, mint QR scan button on the right.
  /// TypeAhead logic (validation, suggestions, selection) unchanged.
  Widget _buildRecipientSection(String Function(String, [Map<String, String>]) t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('send_recipient'), style: GwDesign.sendSectionLabel),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TypeAheadField(
                hideOnEmpty: true,
                key: _addressKeyList[_currentAddressIndex],
                builder: (context, controller, focusNode) {
                  return TextFormField(
                    controller:
                        _addressControllerList[_currentAddressIndex],
                    autocorrect: false,
                    focusNode: focusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: GwDesign.sendInputFill,
                      hintText: t('tx_address'),
                      hintStyle: GwDesign.sendHint,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(GwDesign.radiusCard),
                        borderSide:
                            BorderSide(color: GwDesign.sendInputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(GwDesign.radiusCard),
                        borderSide:
                            BorderSide(color: GwDesign.sendInputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(GwDesign.radiusCard),
                        borderSide: const BorderSide(
                          color: Color(0xFF2FBF8F),
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(GwDesign.radiusCard),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () async {
                          var data =
                              await Clipboard.getData('text/plain');
                          if (data?.text != null) {
                            _addressControllerList[_currentAddressIndex]
                                .text = data!.text!.trim();
                          }
                        },
                        icon: const Icon(
                          Icons.paste_rounded,
                          color: Color(0xFF2FBF8F),
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return t('send_enter_address');
                      }
                      if (_addressControllerList
                              .where((element) => element.text == value)
                              .length >
                          1) {
                        return t('send_address_already_exists');
                      }
                      var sanitized = value.trim();
                      if (validateAddress(
                            sanitized,
                            _availableCoin.networkType,
                          ) ==
                          false) {
                        return t('send_invalid_address');
                      }
                      return null;
                    },
                  );
                },
                suggestionsCallback: (pattern) {
                  return _getSuggestions(pattern);
                },
                itemBuilder: (context, dynamic suggestion) {
                  return ListTile(
                    title: Text(suggestion.addressBookName ?? ''),
                    subtitle: Text(suggestion.address),
                  );
                },
                onSelected: (dynamic suggestion) {
                  _addressControllerList[_currentAddressIndex].text =
                      suggestion.address;
                  _labelControllerList[_currentAddressIndex].text =
                      suggestion.addressBookName;
                },
              ),
            ),
            const SizedBox(width: 8),
            // Mint QR scan button (mockup style)
            if (_appSettings.camerasAvailble)
              InkWell(
                onTap: () async {
                  final result =
                      await Navigator.of(context).pushNamed(
                    Routes.qrScan,
                    arguments: t('scan_qr'),
                  );
                  if (result != null) {
                    _parseQrResult(result as String);
                  }
                },
                borderRadius:
                    BorderRadius.circular(GwDesign.radiusCard),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: GwDesign.feePillActiveFill,
                    borderRadius:
                        BorderRadius.circular(GwDesign.radiusCard),
                  ),
                  child: const Icon(
                    Icons.qr_code_rounded,
                    color: Color(0xFF062A20),
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Optional label field in mockup style.
  Widget _buildLabelField(String Function(String, [Map<String, String>]) t) {
    return TextFormField(
      textInputAction: TextInputAction.done,
      key: _labelKeyList[_currentAddressIndex],
      controller: _labelControllerList[_currentAddressIndex],
      autocorrect: false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: GwDesign.sendInputFill,
        hintText: t('send_label'),
        hintStyle: GwDesign.sendHint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GwDesign.radiusCard),
          borderSide: BorderSide(color: GwDesign.sendInputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GwDesign.radiusCard),
          borderSide: BorderSide(color: GwDesign.sendInputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GwDesign.radiusCard),
          borderSide: const BorderSide(
            color: Color(0xFF2FBF8F),
            width: 1.5,
          ),
        ),
      ),
      maxLength: 32,
    );
  }

  /// Amount input in mockup style: large card with big amount text,
  /// "NUX" unit, and available balance below.
  Widget _buildAmountSection(String Function(String, [Map<String, String>]) t) {
    final available = (widget.wallet.balance / _decimalProduct)
        .toStringAsFixed(_availableCoin.fractions);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('send_amount'), style: GwDesign.sendSectionLabel),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: GwDesign.sendInputFill,
            borderRadius:
                BorderRadius.circular(GwDesign.radiusCard),
            border: Border.all(color: GwDesign.sendInputBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: TextFormField(
                      textInputAction: TextInputAction.done,
                      key: _amountKeyList[_currentAddressIndex],
                      controller:
                          _amountControllerList[_currentAddressIndex],
                      autocorrect: false,
                      style: GwDesign.sendAmountBig,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          _getValidator(_availableCoin.fractions),
                        ),
                      ],
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: GwDesign.sendAmountBig.copyWith(
                          color: const Color(0xFF5A7A6E),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onChanged: (value) {
                        _calcAmountInputHelperText(_currentAddressIndex);
                        if (_amountKeyList[_currentAddressIndex]
                            .currentState!
                            .hasError) {
                          _amountKeyList[_currentAddressIndex]
                              .currentState!
                              .validate();
                          _amountControllerList[_currentAddressIndex]
                              .selection = TextSelection.fromPosition(
                            TextPosition(
                              offset: _amountControllerList[
                                      _currentAddressIndex]
                                  .text
                                  .length,
                            ),
                          );
                        }
                      },
                      validator: (value) {
                        return _amountValidator(value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _fiatInputEnabled
                        ? _appSettings.selectedCurrency
                        : widget.wallet.letterCode,
                    style: GwDesign.sendAmountUnit,
                  ),
                ],
              ),
              if (_amountInputHelperTextList[_currentAddressIndex] !=
                  null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _amountInputHelperTextList[_currentAddressIndex]!,
                    style: GwDesign.sendHint,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                '${t('send_available')}: $available ${widget.wallet.letterCode}',
                style: GwDesign.sendHint,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Network fee tier pills in mockup style (Slow / Normal / Fast).
  Widget _buildFeeSection(String Function(String, [Map<String, String>]) t) {
    final tiers = [
      t('send_fee_slow'),
      t('send_fee_normal'),
      t('send_fee_fast'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('send_network_fee'), style: GwDesign.sendSectionLabel),
        const SizedBox(height: 8),
        Row(
          children: List.generate(3, (index) {
            final active = _feeTier == index;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < 2 ? 8 : 0,
                ),
                child: InkWell(
                  onTap: () => setState(() => _feeTier = index),
                  borderRadius:
                      BorderRadius.circular(GwDesign.radiusPill),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: active
                          ? GwDesign.feePillActiveFill
                          : GwDesign.feePillInactiveFill,
                      borderRadius:
                          BorderRadius.circular(GwDesign.radiusPill),
                      border: Border.all(
                        color: active
                            ? GwDesign.feePillActiveFill
                            : GwDesign.sendInputBorder,
                      ),
                    ),
                    child: Text(
                      tiers[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? GwDesign.feePillActiveText
                            : GwDesign.feePillInactiveText,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Summary card in mockup style: fee tier and total.
  /// The exact fee is estimated at confirmation time (existing flow);
  /// here we show the selected tier and the available balance.
  Widget _buildSummaryCard(String Function(String, [Map<String, String>]) t) {
    final tierName = switch (_feeTier) {
      0 => t('send_fee_slow'),
      2 => t('send_fee_fast'),
      _ => t('send_fee_normal'),
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GwDesign.sendSummaryFill,
        borderRadius:
            BorderRadius.circular(GwDesign.radiusCard),
        border: Border.all(color: GwDesign.sendInputBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t('send_summary_fee'),
                style: GwDesign.sendHint.copyWith(fontSize: 15),
              ),
              Text(
                '$tierName (${t('send_fee_estimated')})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Divider(color: GwDesign.divider, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t('send_summary_total'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '${_amountControllerList[_currentAddressIndex].text.isEmpty ? '0' : _amountControllerList[_currentAddressIndex].text} ${widget.wallet.letterCode}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: GwDesign.sendTotalValue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Primary send button: mint gradient, full width (mockup style).
  /// A true "slide to send" gesture was deemed too complex for Fase B;
  /// this prominent button preserves the existing confirmation flow.
  Widget _buildSendButton(String Function(String, [Map<String, String>]) t) {
    return InkWell(
      onTap: _onSendPressed,
      borderRadius: BorderRadius.circular(GwDesign.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: GwDesign.sendButtonGradient,
          borderRadius: BorderRadius.circular(GwDesign.radiusPill),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              t('send'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Extracted from the original PeerButton onPressed (logic unchanged).
  void _onSendPressed() async {
    if (triggerFormValidation()) {
      _formKey.currentState!.save();
      FocusScope.of(context).unfocus();
      _amountControllerList.asMap().forEach(
        (index, _) {
          _calcAmountInputHelperText(index);
        },
      );
      if (_appSettings.authenticationOptions!['sendTransaction']!) {
        await Auth.requireAuth(
          context: context,
          biometricsAllowed: _appSettings.biometricsAllowed,
          callback: () => _showTransactionConfirmation(context),
        );
      } else {
        _showTransactionConfirmation(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.instance.translate('send_errors_solve'),
          ),
        ),
      );
    }
  }

  /// Secondary actions in mockup-consistent outline style.
  Widget _buildSecondaryActions(
    String Function(String, [Map<String, String>]) t,
  ) {
    return Column(
      children: [
        // QR scan is now the mint button next to the address field;
        // keep the text variant for devices without camera as fallback.
        if (!_appSettings.camerasAvailble)
          _outlineAction(
            t('scan_qr'),
            () async {
              final result =
                  await Navigator.of(context).pushNamed(
                Routes.qrScan,
                arguments: t('scan_qr'),
              );
              if (result != null) {
                _parseQrResult(result as String);
              }
            },
          ),
        _outlineAction(
          t('send_empty'),
          () async {
            setState(() {
              _fiatInputEnabled = false;
            });
            _amountControllerList[_currentAddressIndex].text =
                (widget.wallet.balance / _decimalProduct).toString();
            _calcAmountInputHelperText(_currentAddressIndex);
          },
        ),
        const SizedBox(height: 8),
        _outlineAction(
          t('send_import_csv'),
          () async {
            await importCsv();
          },
        ),
      ],
    );
  }

  Widget _outlineAction(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GwDesign.radiusPill),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(GwDesign.radiusPill),
          border: Border.all(color: GwDesign.sendInputBorder),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2FBF8F),
          ),
        ),
      ),
    );
  }

  /// Expert mode (OP_RETURN metadata) section; logic unchanged.
  Widget _buildExpertSection(String Function(String, [Map<String, String>]) t) {
    return Column(
      children: [
        if (_currentAddressIndex == 0)
          SwitchListTile(
            value: _expertMode,
            activeThumbColor: const Color(0xFF2FBF8F),
            onChanged: (newState) => setState(() {
              _expertMode = newState;
              _opReturnController.text = '';
            }),
            title: Text(
              t('send_add_metadata'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
                color: Colors.white,
              ),
            ),
          ),
        if (_expertMode)
          TextFormField(
            textInputAction: TextInputAction.done,
            key: _opReturnKey,
            controller: _opReturnController,
            autocorrect: false,
            style: const TextStyle(color: Colors.white),
            maxLength: _availableCoin.opreturnSize,
            minLines: 1,
            maxLines: 5,
            buildCounter: (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) {
              var utf8Length =
                  utf8.encode(_opReturnController.text).length;
              return Text(
                '$utf8Length/$maxLength',
                style: GwDesign.sendHint,
              );
            },
            inputFormatters: [
              Utf8LengthLimitingTextInputFormatter(
                _availableCoin.opreturnSize,
              ),
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: GwDesign.sendInputFill,
              hintText: t('send_op_return'),
              hintStyle: GwDesign.sendHint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(GwDesign.radiusCard),
                borderSide:
                    BorderSide(color: GwDesign.sendInputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(GwDesign.radiusCard),
                borderSide:
                    BorderSide(color: GwDesign.sendInputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(GwDesign.radiusCard),
                borderSide: const BorderSide(
                  color: Color(0xFF2FBF8F),
                  width: 1.5,
                ),
              ),
              suffixIcon: IconButton(
                onPressed: () async {
                  var data =
                      await Clipboard.getData('text/plain');
                  if (data?.text != null) {
                    _opReturnController.text = data!.text!.trim();
                  }
                },
                icon: const Icon(
                  Icons.paste_rounded,
                  color: Color(0xFF2FBF8F),
                ),
              ),
            ),
          ),
        if (_expertMode)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              t('wallet_send_label_hint_metadata'),
              textAlign: TextAlign.center,
              style: GwDesign.sendHint.copyWith(fontSize: 12),
            ),
          ),
      ],
    );
  }


  @override
  void didChangeDependencies() async {
    if (_initial == true) {
      _availableCoin = AvailableCoins.getSpecificCoin(widget.wallet.name);
      _walletProvider = Provider.of<WalletProvider>(context);
      _appSettings = context.read<AppSettingsProvider>();

      _availableAddresses =
          await _walletProvider.getWalletAddresses(widget.wallet.name);
      _decimalProduct = AvailableCoins.getDecimalProduct(
        identifier: widget.wallet.name,
      );
      _fiatEnabled = _appSettings.selectedCurrency.isNotEmpty &&
          !widget.wallet.name.contains('Testnet');
      _calcAmountInputHelperText(_currentAddressIndex);

      setState(() {
        _addressControllerList[0].text = widget.address ?? '';
        _labelControllerList[0].text = widget.label ?? '';
        _initial = false;
      });
    }

    super.didChangeDependencies();
  }

  bool triggerFormValidation() {
    return _formKey.currentState!.validate();
  }

  bool _addNewAddress({
    String address = '',
    double amount = 0.0,
    String label = '',
    bool fromImport = false,
  }) {
    if (triggerFormValidation() || fromImport == true) {
      _labelControllerList.add(TextEditingController(text: label));
      _addressControllerList.add(TextEditingController(text: address));
      _amountControllerList.add(TextEditingController(text: amount.toString()));
      _labelKeyList.add(GlobalKey<FormFieldState>());
      _addressKeyList.add(GlobalKey<FormFieldState>());
      _amountKeyList.add(GlobalKey<FormFieldState>());
      _amountInputHelperTextList[_numberOfRecipients] = '';
      _requestedAmountInCoinsList[_numberOfRecipients] = amount;
      if (fromImport == false) {
        _formKey.currentState!.save();
        setState(() {
          _currentAddressIndex = _numberOfRecipients;
        });
      }
      return true;
    }
    return false;
  }

  String? _amountValidator(String value) {
    if (value.isEmpty) {
      return AppLocalizations.instance.translate('send_enter_amount');
    }
    String sanitizedValue = _fiatInputEnabled
        ? _requestedAmountInCoinsList[_currentAddressIndex].toString()
        : value.replaceAll(',', '.');

    if (_fiatInputEnabled == false) {
      _amountControllerList[_currentAddressIndex].text = sanitizedValue;
    }
    _buildRecipientMap();

    var txValueInSatoshis = double.parse(
      (_totalAmountRequestedInCoins * _decimalProduct)
          .toStringAsFixed(_availableCoin.fractions),
    );
    LoggerWrapper.logInfo(
      'SendTab',
      'send_amount',
      'req value $txValueInSatoshis - wallet balance ${widget.wallet.balance}',
    );
    if (sanitizedValue.contains('.') &&
        sanitizedValue.split('.')[1].length > _availableCoin.fractions) {
      return AppLocalizations.instance.translate('send_amount_small');
    }
    if (txValueInSatoshis > widget.wallet.balance ||
        txValueInSatoshis == 0 && widget.wallet.balance == 0) {
      return AppLocalizations.instance.translate('send_amount_exceeds');
    }
    if (txValueInSatoshis < _availableCoin.minimumTxValue &&
        _opReturnController.text.isEmpty) {
      return AppLocalizations.instance.translate(
        'send_amount_below_minimum',
        {'amount': '${_availableCoin.minimumTxValue / _decimalProduct}'},
      );
    }
    if (txValueInSatoshis == widget.wallet.balance &&
        widget.wallet.balance == _availableCoin.minimumTxValue) {
      return AppLocalizations.instance.translate(
        'send_amount_below_minimum_unable',
        {'amount': '${_availableCoin.minimumTxValue / _decimalProduct}'},
      );
    }
    return null;
  }

  Map<String, int> _buildRecipientMap() {
    Map<String, int> recipients = {};
    double totalCoins = 0;
    _amountControllerList.asMap().forEach((key, value) {
      var coins = Decimal.parse(_requestedAmountInCoinsList[key].toString());
      var decimalProduct = Decimal.parse(_decimalProduct.toString());
      recipients[_addressControllerList[key].text.trim()] =
          int.parse((coins * decimalProduct).toString());
      totalCoins += coins.toDouble();
    });

    setState(() {
      _totalAmountRequestedInCoins = totalCoins;
    });
    return recipients;
  }

  Future<BuildResult?> _buildTx() async {
    try {
      // GreenWallet: coins without a fixed fee use the Electrum fee estimate.
      // Falls back to the coin's fixed rate when estimation is unavailable.
      double? feeRatePerKb;
      if (_availableCoin.fixedFee == false) {
        try {
          final blocks = switch (_feeTier) {
            0 => GwDesign.feeBlocksSlow,
            2 => GwDesign.feeBlocksFast,
            _ => GwDesign.feeBlocksNormal,
          };
          feeRatePerKb = await Provider.of<ConnectionProvider>(
            context,
            listen: false,
          ).estimateFeeRate(blocks: blocks);
        } catch (_) {
          feeRatePerKb = null;
        }
      }
      return await _walletProvider.buildTransaction(
        identifier: widget.wallet.name,
        recipients: _buildRecipientMap(),
        fee: 0,
        opReturn: _opReturnKey.currentState?.value ?? '',
        feeRatePerKb: feeRatePerKb,
      );
    } catch (e) {
      if (!mounted) return null;
      LoggerWrapper.logError(
        'SendTab',
        'buildTx',
        'error building tx: ${e.toString()}',
      );
      if (e.runtimeType == CantPayForFeesException) {
        final exception = e as CantPayForFeesException;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.instance.translate(
                'send_errors_cant_pay_fees',
                {
                  'feesMissing':
                      (exception.feesMissing / _decimalProduct).toString(),
                  'letter_code': widget.wallet.letterCode,
                },
              ),
            ),
            duration: const Duration(seconds: 7),
          ),
        );
      }
    }
    return null;
  }

  void _calcAmountInputHelperText(int index) {
    final inputAmount = _amountControllerList[index].text == ''
        ? 1.0
        : double.tryParse(
              _amountControllerList[index].text.replaceAll(',', '.'),
            ) ??
            0;

    if (_fiatEnabled == false) {
      setState(() {
        _requestedAmountInCoinsList[index] = inputAmount;
      });
      return;
    }

    final fiatPrice = PriceTicker.renderPrice(
      1,
      _appSettings.selectedCurrency,
      widget.wallet.letterCode,
      _appSettings.exchangeRates,
    );

    String priceInCoins =
        (_fiatInputEnabled ? inputAmount * (1 / _coinValue) : inputAmount)
            .toStringAsFixed(_availableCoin.fractions);

    String result = '';
    if (_fiatInputEnabled) {
      result =
          '$inputAmount ${_appSettings.selectedCurrency} = $priceInCoins ${widget.wallet.letterCode}';
    } else {
      result =
          '$inputAmount ${widget.wallet.letterCode} = ${(inputAmount * fiatPrice).toStringAsFixed(2)} ${_appSettings.selectedCurrency}';
    }
    setState(() {
      _amountInputHelperTextList[index] = result;
      _requestedAmountInCoinsList[index] = double.parse(priceInCoins);
      _coinValue = fiatPrice;
    });
  }

  Future<List> _getSuggestions(String pattern) async {
    final res = _availableAddresses.where((element) {
      if (element.isOurs == false && element.address.contains(pattern)) {
        return true;
      } else if (element.isOurs == false &&
          element.addressBookName.contains(pattern)) {
        return true;
      }
      return false;
    }).toList();
    return res;
  }

  RegExp _getValidator(int fractions) {
    var expression = r'^([1-9]{1}[0-9]{0,' +
        fractions.toString() +
        r'}(,[0-9]{3})*(.[0-9]{0,' +
        fractions.toString() +
        r'})?|[1-9]{1}[0-9]{0,}(.[0-9]{0,' +
        fractions.toString() +
        r'})?|0(.[0-9]{0,' +
        fractions.toString() +
        r'})?|(.[0-9]{1,' +
        fractions.toString() +
        r'})?)$';

    return RegExp(expression);
  }

  void _parseQrResult(String code) {
    var parsed = Uri.parse(code);
    parsed.queryParameters.forEach((key, value) {
      if (key == 'amount') {
        _amountControllerList[_currentAddressIndex].text = value;
      } else if (key == 'label') {
        _labelControllerList[_currentAddressIndex].text = value;
      }
    });

    _addressControllerList[_currentAddressIndex].text = parsed.path;
    triggerFormValidation();
  }

  _removeAddress(int index) {
    _labelControllerList.removeAt(index);
    _addressControllerList.removeAt(index);
    _amountControllerList.removeAt(index);
    _labelKeyList.removeAt(index);
    _addressKeyList.removeAt(index);
    _amountKeyList.removeAt(index);
    _amountInputHelperTextList.remove(index);
    _requestedAmountInCoinsList.remove(index);

    setState(() {
      _numberOfRecipients--;
      if (_currentAddressIndex - 1 > 0) {
        _currentAddressIndex--;
      } else {
        _currentAddressIndex = 0;
      }
    });
  }

  void _showTransactionConfirmation(context) async {
    var buildResult = await _buildTx();
    if (buildResult != null) {
      await Navigator.of(context).pushNamed(
        Routes.transactionConfirmation,
        arguments: TransactionConfirmationArguments(
          buildResult: buildResult,
          decimalProduct: _decimalProduct,
          coinLetterCode: widget.wallet.letterCode,
          coinIdentifier: widget.wallet.name,
          callBackAfterSend: () => widget.changeTab(WalletTab.transactions),
          fiatPricePerCoin: _coinValue,
          fiatCode: _appSettings.selectedCurrency,
        ),
      );

      //persist labels
      _labelControllerList.asMap().forEach(
        (index, controller) {
          if (controller.text != '') {
            _walletProvider.updateOrCreateAddressLabel(
              identifier: widget.wallet.name,
              address: _addressControllerList[index].text,
              label: controller.text,
            );
          }
        },
      );
    }
  }

  Future<void> importCsv() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    String csv;
    if (result != null) {
      if (kIsWeb) {
        csv = String.fromCharCodes(
          result.files.single.bytes!,
        );
      } else {
        csv = await File(result.files.single.path!).readAsString();
      }
      final parsed = fast_csv.parse(csv);
      var i = 0;
      for (final row in parsed) {
        final address = row[0];
        final amount = double.parse(
          row[1].replaceAll(',', '.'),
        );
        if (i == 0) {
          _addressControllerList[0].text = address;
          _amountControllerList[0].text = amount.toString();
          _requestedAmountInCoinsList[0] = amount;
        } else {
          _addNewAddress(
            address: address,
            amount: amount,
            label: '',
            fromImport: true,
          );
          setState(() {
            _numberOfRecipients++;
          });
        }
        i++;
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../providers/connection_provider.dart';
import '../../../tools/share_wrapper.dart';
import '../../../providers/wallet_provider.dart';
import '/../tools/app_localizations.dart';
import '/../models/available_coins.dart';
import '/../models/coin.dart';
import '/../models/hive/coin_wallet.dart';
import '../../../tools/gw_design.dart';
import '/../widgets/double_tab_to_clipboard.dart';
import '/../widgets/service_container.dart';
import '/../widgets/wallet/wallet_balance_header.dart';

class ReceiveTab extends StatefulWidget {
  final String unusedAddress;
  final BackendConnectionState connectionState;
  final CoinWallet wallet;
  const ReceiveTab({
    required this.unusedAddress,
    required this.connectionState,
    required this.wallet,
    super.key,
  });

  @override
  State<ReceiveTab> createState() => _ReceiveTabState();
}

class _ReceiveTabState extends State<ReceiveTab> {
  bool _initial = true;
  final amountController = TextEditingController();
  final labelController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _amountKey = GlobalKey<FormFieldState>();
  final _labelKey = GlobalKey<FormFieldState>();
  late Coin _availableCoin;
  String? _qrString;

  @override
  void didChangeDependencies() {
    if (_initial == true) {
      _availableCoin = AvailableCoins.getSpecificCoin(widget.wallet.name);
      stringBuilder();
      setState(() {
        _initial = false;
      });
    }
    super.didChangeDependencies();
  }

  void stringBuilder() {
    final convertedValue = amountController.text == ''
        ? 0
        : double.parse(amountController.text.replaceAll(',', '.'));
    final label = labelController.text;
    var builtString = '';

    if (convertedValue == 0) {
      builtString = '${_availableCoin.uriCode}:${widget.unusedAddress}';
      if (label != '') {
        builtString =
            '${_availableCoin.uriCode}:${widget.unusedAddress}?label=$label';
      }
    } else {
      builtString =
          '${_availableCoin.uriCode}:${widget.unusedAddress}?amount=$convertedValue';
      if (label != '') {
        builtString =
            '${_availableCoin.uriCode}:${widget.unusedAddress}?amount=$convertedValue&label=$label';
      }
    }
    setState(() {
      _qrString = builtString;
    });
  }

  RegExp getValidator(int fractions) {
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
                    children: <Widget>[
                      // QR code in a white rounded card (needed for scanning)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              GwDesign.radiusCard,
                            ),
                            border: Border.all(
                              color: GwDesign.receiveCardBorder,
                              width: 2,
                            ),
                          ),
                          child: _qrString != null
                              ? QrImageView(
                                  data: _qrString!,
                                  size: 200,
                                )
                              : const SizedBox(
                                  width: 200,
                                  height: 200,
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Address card (mockup style)
                      Text(
                        t('receive_address'),
                        style: GwDesign.sendSectionLabel,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: GwDesign.receiveCardFill,
                          borderRadius: BorderRadius.circular(
                            GwDesign.radiusCard,
                          ),
                          border: Border.all(
                            color: GwDesign.receiveCardBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: DoubleTabToClipboard(
                                withHintText: false,
                                clipBoardData: widget.unusedAddress,
                                child: SelectableText(
                                  widget.unusedAddress,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: widget.unusedAddress,
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      t('receive_copied'),
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: GwDesign.feePillActiveFill,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.copy_rounded,
                                  color: Color(0xFF062A20),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Label field
                      TextFormField(
                        textInputAction: TextInputAction.done,
                        key: _labelKey,
                        controller: labelController,
                        autocorrect: false,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (String newString) {
                          stringBuilder();
                        },
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
                            borderRadius: BorderRadius.circular(
                              GwDesign.radiusCard,
                            ),
                            borderSide: BorderSide(
                              color: GwDesign.sendInputBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              GwDesign.radiusCard,
                            ),
                            borderSide: BorderSide(
                              color: GwDesign.sendInputBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              GwDesign.radiusCard,
                            ),
                            borderSide: const BorderSide(
                              color: Color(0xFF2FBF8F),
                              width: 1.5,
                            ),
                          ),
                        ),
                        maxLength: 32,
                      ),
                      const SizedBox(height: 12),
                      // Amount field
                      TextFormField(
                        textInputAction: TextInputAction.done,
                        key: _amountKey,
                        controller: amountController,
                        onChanged: (String newString) {
                          stringBuilder();
                        },
                        autocorrect: false,
                        style: const TextStyle(color: Colors.white),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            getValidator(_availableCoin.fractions),
                          ),
                        ],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: GwDesign.sendInputFill,
                          hintText: t('receive_requested_amount'),
                          hintStyle: GwDesign.sendHint,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          suffix: Text(
                            widget.wallet.letterCode,
                            style: GwDesign.sendAmountUnit.copyWith(
                              fontSize: 16,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              GwDesign.radiusCard,
                            ),
                            borderSide: BorderSide(
                              color: GwDesign.sendInputBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              GwDesign.radiusCard,
                            ),
                            borderSide: BorderSide(
                              color: GwDesign.sendInputBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              GwDesign.radiusCard,
                            ),
                            borderSide: const BorderSide(
                              color: Color(0xFF2FBF8F),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return t('receive_enter_amount');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Share button (gradient, mockup style)
                      InkWell(
                        onTap: () async {
                          if (labelController.text != '') {
                            context
                                .read<WalletProvider>()
                                .updateOrCreateAddressLabel(
                                  identifier: widget.wallet.name,
                                  address: widget.unusedAddress,
                                  label: labelController.text,
                                );
                          }
                          await ShareWrapper.share(
                            context: context,
                            message: _qrString ?? widget.unusedAddress,
                          );
                        },
                        borderRadius: BorderRadius.circular(
                          GwDesign.radiusPill,
                        ),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: GwDesign.sendButtonGradient,
                            borderRadius: BorderRadius.circular(
                              GwDesign.radiusPill,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.share_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                t('receive_share'),
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
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t('wallet_receive_label_hint'),
                        textAlign: TextAlign.center,
                        style: GwDesign.sendHint.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t('wallet_receive_label_hint_privacy'),
                        textAlign: TextAlign.center,
                        style: GwDesign.sendHint.copyWith(fontSize: 12),
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

}

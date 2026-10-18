import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../providers/app_settings_provider.dart';
import 'logger_wrapper.dart';

class PriceTicker {
  /// Qutrade public API base (no auth required for public endpoints).
  static const String _qutradeBase = 'https://qutrade.io/api/v2';

  static Future<Map<String, dynamic>> getDataFromTicker() async {
    // GreenWallet: NUX price from Qutrade public API (no auth).
    // Returns {fiat: rate, coin: priceInUsd} for renderPrice().
    // Also fetches USD->IDR rate so the community can see IDR values.
    try {
      final nuxResponse = await http.get(
        Uri.parse('$_qutradeBase/spot_markets?pair=NUX_USDT&field=last'),
      ).timeout(const Duration(seconds: 10));
      double? priceUsd;
      if (nuxResponse.statusCode == 200) {
        final data = jsonDecode(nuxResponse.body) as Map<String, dynamic>;
        final payload =
            (data['payload'] as Map<String, dynamic>?)?['NUX_USDT']
                as Map<String, dynamic>?;
        final lastStr = payload?['last'] as String?;
        priceUsd = double.tryParse(lastStr ?? '');
      }
      if (priceUsd == null || priceUsd <= 0) return {};

      // USD->IDR rate (free, no auth).
      double idrRate = 0;
      try {
        final fxResponse = await http
            .get(Uri.parse('https://open.er-api.com/v6/latest/USD'))
            .timeout(const Duration(seconds: 10));
        if (fxResponse.statusCode == 200) {
          final fxData = jsonDecode(fxResponse.body) as Map<String, dynamic>;
          idrRate =
              ((fxData['rates'] as Map<String, dynamic>?)?['IDR'] as num?)
                      ?.toDouble() ??
                  0;
        }
      } catch (_) {
        // IDR optional; USD still works without it.
      }

      final result = <String, dynamic>{
        'USD': 1.0,
        'NUX': priceUsd,
        'tNUX': priceUsd, // testnet mirrors mainnet price
      };
      if (idrRate > 0) {
        result['IDR'] = idrRate;
      }
      return result;
    } catch (e) {
      LoggerWrapper.logInfo(
        'PriceTicker',
        'getDataFromTicker',
        'Price fetch failed: $e',
      );
    }
    return {};
  }

  static Map currencySymbols = {
    'AED': 'د.إ',
    'AFN': '؋',
    'ALL': 'Lek',
    'AMD': '֏',
    'ANG': 'ƒ',
    'AOA': 'Kz',
    'ARS': '\$',
    'AUD': 'A\$',
    'AWG': 'ƒ',
    'AZN': '₼',
    'BAM': 'KM',
    'BBD': '\$',
    'BDT': '৳',
    'BHD': 'ب.د',
    'BIF': 'FBu',
    'BMD': '\$',
    'BND': '\$',
    'BOB': 'Bs.',
    'BRL': 'R\$',
    'BSD': '\$',
    'BTN': 'Nu.',
    'BWP': 'P',
    'BYN': 'Br',
    'BZD': 'BZ\$',
    'CAD': '\$',
    'CDF': 'FC',
    'CHF': 'Fr.',
    'CLF': 'UF',
    'CLP': '\$',
    'CNY': '¥',
    'COP': '\$',
    'CRC': '₡',
    'CUP': '\$',
    'CVE': 'Esc',
    'CZK': 'Kč',
    'DJF': 'Fdj',
    'DKK': 'Kr.',
    'DOP': 'RD\$',
    'DZD': 'د.ج',
    'EGP': 'ج.م',
    'ERN': 'Nfk',
    'ETB': 'ብር',
    'EUR': '€',
    'FJD': 'FJ\$',
    'GBP': '£',
    'GEL': '₾',
    'GHS': '₵',
    'GIP': '£',
    'GMD': 'D',
    'GNF': 'FG',
    'GTQ': 'Q',
    'GYD': '\$',
    'HKD': '\$',
    'HNL': 'L',
    'HTG': 'G',
    'HUF': 'Ft',
    'IDR': 'Rp',
    'ILS': '₪',
    'INR': '₹',
    'IQD': 'ع.د',
    'IRR': '﷼',
    'ISK': 'kr',
    'JMD': '\$',
    'JOD': 'د.ا',
    'JPY': '¥',
    'KES': 'KSh',
    'KGS': 'лв',
    'KHR': '៛',
    'KMF': 'CF',
    'KPW': '₩',
    'KRW': '₩',
    'KWD': 'د.ك',
    'KYD': '\$',
    'KZT': '₸',
    'LAK': '₭',
    'LBP': 'ل.ل',
    'LKR': '₨',
    'LRD': '\$',
    'LSL': 'L',
    'LYD': 'ل.د',
    'MAD': 'د.م.',
    'MDL': 'L',
    'MGA': 'Ar',
    'MKD': 'ден',
    'MMK': 'K',
    'MNT': '₮',
    'MOP': 'P',
    'MRU': 'UM',
    'MUR': '₨',
    'MVR': 'ރ.',
    'MWK': 'MK',
    'MXN': '\$',
    'MYR': 'RM',
    'MZN': 'MT',
    'NAD': '\$',
    'NGN': '₦',
    'NIO': 'C\$',
    'NOK': 'kr',
    'NPR': '₨',
    'NZD': '\$',
    'OMR': 'ر.ع.',
    'PAB': 'B/.',
    'PEN': 'S/',
    'PGK': 'K',
    'PHP': '₱',
    'PKR': '₨',
    'PLN': 'zł',
    'PYG': '₲',
    'QAR': 'ر.ق',
    'RON': 'L',
    'RSD': 'дин',
    'RUB': '₽',
    'RWF': 'FRw',
    'SAR': 'ر.س',
    'SBD': '\$',
    'SCR': '₨',
    'SDG': 'ج.س.',
    'SEK': 'kr',
    'SGD': '\$',
    'SHP': '£',
    'SLL': 'Le',
    'SOS': 'S',
    'SRD': '\$',
    'SSP': '£',
    'STN': 'Db',
    'SVC': '\$',
    'SYP': '£',
    'SZL': 'L',
    'THB': '฿',
    'TJS': 'SM',
    'TMT': 'T',
    'TND': 'د.ت',
    'TOP': 'T\$',
    'TRY': '₺',
    'TTD': '\$',
    'TWD': 'NT\$',
    'TZS': 'TSh',
    'UAH': '₴',
    'UGX': 'USh',
    'USD': '\$',
    'UYU': '\$U',
    'UZS': 'лв',
    'VND': '₫',
    'VUV': 'Vt',
    'WST': 'WS\$',
    'XAF': 'FCFA',
    'XCD': '\$',
    'XOF': 'CFA',
    'XPF': '₣',
    'YER': '﷼',
    'ZAR': 'R',
    'ZMW': 'ZK',
    'ZWL': 'Z\$',
  };

  static double renderPrice(
    double amount,
    String currencySymbol,
    String coinLetterCode,
    Map prices,
  ) {
    if (prices.isEmpty || prices.containsKey(coinLetterCode) == false) {
      return 0.0;
    }
    if (currencySymbol != 'USD') {
      return prices[currencySymbol] * amount * prices[coinLetterCode];
    }
    return amount * prices[coinLetterCode];
  }

  static void checkUpdate(AppSettingsProvider settings) async {
    LoggerWrapper.logInfo(
      'PriceTicker',
      'checkUpdate',
      'checking price update',
    );
    //check if last update was longer than an hour ago
    final oneHourAgo = (DateTime.now())
        .subtract(const Duration(minutes: Duration.minutesPerHour));
    if (settings.latestTickerUpdate.isBefore(oneHourAgo)) {
      LoggerWrapper.logInfo(
        'PriceTicker',
        'checkUpdate',
        'last update older than 1 hour (${settings.latestTickerUpdate})',
      );
      //time to update
      //get data
      final data = await getDataFromTicker();

      //check if data still contains selectedCurrency
      if (!data.containsKey(settings.selectedCurrency)) {
        settings.setSelectedCurrency('USD'); //fallback to USD
      }

      if (mapEquals(data, settings.exchangeRates) == false) {
        //stored exchange rates need update
        final valuesValid = data.values.every(
          (element) =>
              element.runtimeType == double || element.runtimeType == int,
        );
        if (valuesValid) {
          //data valid
          LoggerWrapper.logInfo(
            'PriceTicker',
            'checkUpdate',
            'price data updated $data',
          );
          settings.setExchangeRates(data);
        } else {
          LoggerWrapper.logError(
            'PriceTicker',
            'checkUpdate',
            'parser data not valid',
          );
        }
      }

      //update lastTickerUpdate
      settings.setLatestTickerUpdate(DateTime.now());
    } else {
      LoggerWrapper.logInfo(
        'PriceTicker',
        'checkUpdate',
        'last update happened within the hour. ${settings.latestTickerUpdate}',
      );
    }
  }
}

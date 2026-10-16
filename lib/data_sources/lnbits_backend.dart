import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/lnbits_payment.dart';
import '../tools/logger_wrapper.dart';

/// Number of millisatoshis in one nusan.
const int lnMsatPerNusan = 1000;

/// Client for the LNbits core API (no extensions required).
///
/// The base URL is configurable (never hardcoded) because the testnet
/// instance is plain HTTP and not hardened yet; switching to HTTPS must not
/// require an app update.
class LnbitsBackend {
  final String baseUrl;
  final String inkey;
  final String adminkey;

  LnbitsBackend({
    required this.baseUrl,
    required this.inkey,
    required this.adminkey,
  });

  String get _base => baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;

  /// True when the transport is encrypted (https).
  bool get isSecure => _base.startsWith('https://');

  Map<String, String> _headers(String key) => {
        'X-Api-Key': key,
        'Content-Type': 'application/json',
      };

  /// Wallet balance in nusan. The API returns msat.
  Future<int> getBalanceNusan() async {
    final resp = await http
        .get(Uri.parse('$_base/api/v1/wallet'), headers: _headers(inkey))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw LnbitsException('getBalance failed: HTTP ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final msat = (data['balance'] as num).toInt();
    return msat ~/ lnMsatPerNusan;
  }

  /// Create an invoice for [amountNusan] nusan with an optional [memo].
  /// The API amount unit is nusan (server runs LNBITS_DENOMINATION=sats).
  /// Returns the bolt11 payment request.
  Future<String> createInvoice({
    required int amountNusan,
    String memo = '',
  }) async {
    final resp = await http
        .post(
          Uri.parse('$_base/api/v1/payments'),
          headers: _headers(inkey),
          body: jsonEncode({
            'out': false,
            'amount': amountNusan,
            'memo': memo,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw LnbitsException(
          'createInvoice failed: HTTP ${resp.statusCode}: ${resp.body}',);
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final paymentRequest = data['payment_request'] as String?;
    if (paymentRequest == null || paymentRequest.isEmpty) {
      throw const LnbitsException('createInvoice: empty payment_request');
    }
    return paymentRequest;
  }

  /// Pay a bolt11 invoice. Requires the adminkey. Returns the checking id.
  ///
  /// WARNING: the server performs no amount check — the caller MUST decode
  /// the invoice and validate its amount against the expected amount before
  /// calling this.
  Future<String> payInvoice(String bolt11) async {
    final resp = await http
        .post(
          Uri.parse('$_base/api/v1/payments'),
          headers: _headers(adminkey),
          body: jsonEncode({'out': true, 'bolt11': bolt11}),
        )
        .timeout(const Duration(seconds: 60));
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw LnbitsException(
          'payInvoice failed: HTTP ${resp.statusCode}: ${resp.body}',);
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return (data['checking_id'] as String?) ?? '';
  }

  /// Payment history, newest first.
  Future<List<LnbitsPayment>> getPayments() async {
    final resp = await http
        .get(Uri.parse('$_base/api/v1/payments'), headers: _headers(inkey))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw LnbitsException('getPayments failed: HTTP ${resp.statusCode}');
    }
    final list = jsonDecode(resp.body) as List<dynamic>;
    final payments = list
        .map((e) => LnbitsPayment.fromJson(e as Map<String, dynamic>))
        .toList();
    payments.sort((a, b) => b.time.compareTo(a.time));
    return payments;
  }

  /// Subscribe to realtime payment events. [onEvent] fires on every push
  /// message; the caller should refresh balance and history there.
  /// Returns the subscription; the caller must cancel it.
  StreamSubscription<dynamic> listenPayments(void Function() onEvent) {
    final wsBase = _base.replaceFirst(RegExp(r'^http'), 'ws');
    final channel = WebSocketChannel.connect(
      Uri.parse('$wsBase/api/v1/ws/$inkey'),
    );
    return channel.stream.listen(
      (_) => onEvent(),
      onError: (Object e) =>
          LoggerWrapper.logError('LnbitsBackend', 'ws', 'WS error: $e'),
      onDone: () =>
          LoggerWrapper.logInfo('LnbitsBackend', 'ws', 'WS closed by server'),
    );
  }
}

class LnbitsException implements Exception {
  final String message;
  const LnbitsException(this.message);

  @override
  String toString() => 'LnbitsException: $message';
}

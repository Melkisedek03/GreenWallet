import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:decimal/decimal.dart';

/// Decoded view of a bolt11 invoice, normalized to nusan.
///
/// Strider's LNbits fork uses custom HRPs (`lntn` testnet, `lnn` mainnet);
/// decoding relies on the GreenWallet fork of `bolt11_decoder` which knows
/// these prefixes. In the fork, 1 nusan plays the role of 1 sat, so the
/// BTC-denominated bolt11 amount converts with 1e8.
class LnbitsInvoice {
  final String bolt11;
  final int amountNusan;
  final String memo;
  final DateTime timestamp;
  final int expirySeconds;
  final String paymentHash;

  const LnbitsInvoice({
    required this.bolt11,
    required this.amountNusan,
    required this.memo,
    required this.timestamp,
    required this.expirySeconds,
    required this.paymentHash,
  });

  bool get isExpired =>
      DateTime.now().isAfter(timestamp.add(Duration(seconds: expirySeconds)));

  /// Expected HRPs for Nusacoin networks.
  static const List<String> knownPrefixes = ['lntn', 'lnn'];

  static LnbitsInvoice decode(String bolt11) {
    final raw = bolt11.trim().toLowerCase();
    final req = Bolt11PaymentRequest(raw);

    String memo = '';
    int expirySeconds = 3600; // BOLT11 default
    String paymentHash = '';
    for (final t in req.tags) {
      switch (t.type) {
        case 'description':
          memo = t.data as String? ?? '';
          break;
        case 'expiry':
          expirySeconds = (t.data as int?) ?? expirySeconds;
          break;
        case 'payment_hash':
          paymentHash = t.data as String? ?? '';
          break;
      }
    }

    // req.amount is BTC-denominated; 1 nusan == 1 sat in the fork.
    final nusan =
        (req.amount * Decimal.fromInt(100000000)).toBigInt().toInt();

    return LnbitsInvoice(
      bolt11: raw,
      amountNusan: nusan,
      memo: memo,
      timestamp:
          DateTime.fromMillisecondsSinceEpoch(req.timestamp.toInt() * 1000),
      expirySeconds: expirySeconds,
      paymentHash: paymentHash,
    );
  }
}

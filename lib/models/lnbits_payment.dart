import '../data_sources/lnbits_backend.dart';

/// A single LNbits payment history entry.
///
/// The API reports amounts in millisatoshis, signed: positive means incoming,
/// negative means outgoing.
class LnbitsPayment {
  final int amountMsat;
  final String memo;
  final DateTime time;
  final String status; // pending | success | failed
  final String? bolt11;
  final String? paymentHash;

  const LnbitsPayment({
    required this.amountMsat,
    required this.memo,
    required this.time,
    required this.status,
    this.bolt11,
    this.paymentHash,
  });

  /// Amount in nusan (truncated, never rounded up).
  int get amountNusan => amountMsat ~/ lnMsatPerNusan;

  bool get isIncoming => amountMsat > 0;
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';

  factory LnbitsPayment.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;
    try {
      // LNbits 1.6 serializes time as an ISO 8601 string, not epoch.
      parsedTime = DateTime.parse(json['time'] as String);
    } catch (_) {
      parsedTime = DateTime.now();
    }
    return LnbitsPayment(
      amountMsat: (json['amount'] as num).toInt(),
      memo: (json['memo'] as String?) ?? '',
      time: parsedTime,
      status: (json['status'] as String?) ?? 'success',
      bolt11: json['bolt11'] as String?,
      paymentHash: json['payment_hash'] as String?,
    );
  }
}

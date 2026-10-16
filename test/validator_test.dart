import 'package:coinlib_flutter/coinlib_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenwallet/models/available_coins.dart';
import 'package:greenwallet/tools/validators.dart';

void main() async {
  //init coinlib
  await loadCoinlib();

  group('validators', () {
    final network = AvailableCoins.getSpecificCoin('peercoin').networkType;
    test('validateAddress', () {
      assert(
        validateAddress('PXDR4KZn2WdTocNx1GPJXR96PfzZBvWqKQ', network) == true,
      );
      assert(
        validateAddress('PXDR4KZn2WdTocNx1GPJXR96PfzZBvWqKq', network) == false,
      );
    });

    test('validateWIFPrivKey', () {
      assert(
        validateWIFPrivKey(
              'UBhubKxzjdkdPEwMX83nKS1RNgJCWBXFoE7pDrXaQJA3MjeFL8cf',
            ) ==
            true,
      );
      assert(
        validateWIFPrivKey(
              'UBhubKxzjdkdPEwMX83nKS1RNgJCWBXFoE7pDrXaQJA3MjeFL8cF',
            ) ==
            false,
      );
    });
  });
}

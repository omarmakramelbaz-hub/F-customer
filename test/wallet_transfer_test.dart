import 'package:flutter_test/flutter_test.dart';

import '../lib/view/layout/wallet/model/wallet_transfer.dart';

void main() {
  test(
    'same phone stays bound to the chosen wallet and confirmed recipient',
    () {
      for (final wallet in TransferWallet.values) {
        final preview = WalletTransferPreview.fromJson(
          {
            'user_id': 101 + wallet.index,
            'username': 'Recipient',
            'target_wallet': wallet.value,
            'transfer_token': 'signed-${wallet.value}',
          },
          wallet: wallet,
          mobile: '01012345678',
          amount: 50,
        );
        expect(preview.payload['target_wallet'], wallet.value);
        expect(preview.payload['recipient_id'], 101 + wallet.index);
        expect(preview.payload['transfer_token'], 'signed-${wallet.value}');
        expect(preview.payload['mobile'], '01012345678');
        expect(preview.payload['amount'], 50);
        expect(preview.payload.containsKey('account_type'), isFalse);
      }
    },
  );
  test(
    'old or mismatched backend confirmation cannot authorize a transfer',
    () {
      for (final response in <Map<String, dynamic>>[
        {'user_id': 10, 'username': 'Old backend'},
        {
          'user_id': 10,
          'username': 'Wrong app',
          'target_wallet': 'fasakhansta_customer',
          'transfer_token': 'token',
        },
        {
          'username': 'No recipient',
          'target_wallet': 'go_customer',
          'transfer_token': 'token',
        },
      ]) {
        expect(
          () => WalletTransferPreview.fromJson(
            response,
            wallet: TransferWallet.goCustomer,
            mobile: '01012345678',
            amount: 50,
          ),
          throwsFormatException,
        );
      }
    },
  );
}

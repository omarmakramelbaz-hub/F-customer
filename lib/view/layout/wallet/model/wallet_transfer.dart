// These wire values identify the recipient app, never the sender's app.
enum TransferWallet {
  goCustomer('go_customer', 'walletGoCustomer'),
  goPartner('go_partner', 'walletGoPartner'),
  fasakhanstaCustomer('fasakhansta_customer', 'walletFasakhanstaCustomer');

  const TransferWallet(this.value, this.labelKey);
  final String value;
  final String labelKey;
}

class WalletTransferPreview {
  const WalletTransferPreview({
    required this.wallet,
    required this.mobile,
    required this.amount,
    required this.recipientId,
    required this.recipientName,
    required this.token,
  });
  final TransferWallet wallet;
  final String mobile;
  final num amount;
  final int recipientId;
  final String recipientName;
  final String token;

  factory WalletTransferPreview.fromJson(
    Map<String, dynamic> json, {
    required TransferWallet wallet,
    required String mobile,
    required num amount,
  }) {
    final id = int.tryParse(json['user_id'].toString());
    final token = json['transfer_token']?.toString() ?? '';
    final name = json['username']?.toString().trim() ?? '';
    // An old backend must never silently accept an unscoped transfer.
    if (id == null ||
        id < 1 ||
        token.isEmpty ||
        name.isEmpty ||
        json['target_wallet'] != wallet.value) {
      throw const FormatException('Invalid scoped wallet confirmation');
    }
    return WalletTransferPreview(
      wallet: wallet,
      mobile: mobile,
      amount: amount,
      recipientId: id,
      recipientName: name,
      token: token,
    );
  }

  Map<String, dynamic> get payload => {
    'mobile': mobile,
    'amount': amount,
    'target_wallet': wallet.value,
    'recipient_id': recipientId,
    'transfer_token': token,
  };
}

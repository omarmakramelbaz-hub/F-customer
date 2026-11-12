import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/date_methods.dart';
import '../../auth/controller/auth_controller.dart';
import '../model/wallet_model.dart';

class RecentTransactionsWidget extends StatelessWidget {
  final List<WalletModel>? wallet;
  const RecentTransactionsWidget({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    final items = wallet ?? const <WalletModel>[];
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: List.generate(items.length, (index) {
        final transaction = items[index];
        final authId = context.read<AuthController>().profile?.id;
        final isFromMe = authId == transaction.fromUser;
        final isCredit = transaction.type == 'charging' ||
            (transaction.toUser == authId && !isFromMe);
        final amount = transaction.amount ?? 0;
        final color = isCredit ? Colors.green.shade700 : Colors.deepOrange;
        final icon = transaction.type == 'charging'
            ? Icons.add_card_outlined
            : transaction.type == 'transfer'
                ? Icons.swap_horiz_rounded
                : transaction.type == 'shipping'
                    ? Icons.shopping_bag_outlined
                    : Icons.account_balance_wallet_outlined;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: FasakhanstaBrand.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.greyColor.withValues(alpha: .12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buildTransaction(transaction.type ?? ''),
                      style: AppTextStyle.text16MS(),
                    ),
                    if (transaction.orderNo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        transaction.orderNo!,
                        style: AppTextStyle.text14RM(),
                      ),
                    ],
                    if (transaction.fromUserName != null &&
                        transaction.toUserName != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${isFromMe ? 'من محفظتك' : transaction.fromUserName} ← ${transaction.toUser == authId ? 'محفظتك' : transaction.toUserName}',
                        style: AppTextStyle.text14RM(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 5),
                    Text(
                      DateMethods.formatToDate(transaction.createdAt ?? ''),
                      style: AppTextStyle.text14RM(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${isCredit ? '+' : '-'} ${amount.toStringAsFixed(2)} ج',
                style: AppTextStyle.text16BS().copyWith(color: color),
              ),
            ],
          ),
        );
      }),
    );
  }

  String buildTransaction(String transaction) {
    switch (transaction) {
      case 'transfer':
        return 'تحويل أموال';
      case 'charging':
        return 'شحن المحفظة';
      case 'withdraw':
        return 'سحب من المحفظة';
      case 'shipping':
        return 'دفع طلب';
      default:
        return transaction.isEmpty ? 'عملية محفظة' : transaction;
    }
  }
}

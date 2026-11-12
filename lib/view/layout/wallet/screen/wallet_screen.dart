import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/utils.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/page_container/page_container.dart';
import '../../auth/controller/auth_controller.dart';
import '../../my_account/account_app_bar/account_app_bar.dart';
import '../../my_account/controller/my_account_controller.dart';
import '../../my_account/screen/personal_information_screen.dart';
import '../bottom_sheet/charge_wallet_bottom_sheet.dart';
import '../bottom_sheet/mony_transfer_bottom_sheet.dart';
import '../controller/wallet_controller.dart';
import '../model/wallet_model.dart';
import '../widget/my_current_balance_widget.dart';
import '../widget/recent_transactions_widget.dart';

class WalletScreen extends StatefulWidget {
  static const String routeName = 'WalletScreen';
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late PusherController _pusherController;
  String? pusherWalletAmount;

  @override
  void initState() {
    super.initState();
    _pusherController = context.read<PusherController>();
    _pusherController.addEventListener('balance.updated', _handleWalletUpdate);
  }

  void _handleWalletUpdate(PusherEvent event) {
    try {
      final jsonData = jsonDecode(event.data) as Map<String, dynamic>;
      final amount = jsonData['user_balance']?.toString() ?? '0';
      pusherWalletAmount = num.parse(amount).toStringAsFixed(2);
      if (mounted) {
        final transaction = WalletModel.fromJson(jsonData);
        context.read<WalletController>().updateWallet(transaction: transaction);
      }
    } catch (e, stackTrace) {
      log('Error handling wallet update: $e');
      log('$stackTrace');
    }
  }

  @override
  void dispose() {
    _pusherController.removeEventListener(
      'balance.updated',
      _handleWalletUpdate,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<WalletController, MyAccountController>(
      builder: (context, walletController, myAccountController, _) {
        final authController = context.read<AuthController>();
        final balance =
            pusherWalletAmount ??
            walletController.wallet?.balance?.toStringAsFixed(2) ??
            '0.00';

        return Scaffold(
          extendBody: true,
          body: PageContainer(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomAccountAppBar(title: 'theWallet'.tr),
                  const SizedBox(height: 18),
                  MyCurrentBalanceWidget(
                    wallet: walletController.wallet,
                    pusherWalletAmount: pusherWalletAmount,
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActions(
                    context,
                    walletController,
                    myAccountController,
                    authController,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'عروض استخدام رصيد المحفظة',
                          style: AppTextStyle.text18BS(),
                        ),
                      ),
                      Text(
                        'عرض الكل',
                        style: AppTextStyle.text16MS().copyWith(
                          color: AppColors.mainAppColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildWalletOffer(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'سجل العمليات',
                          style: AppTextStyle.text18BS(),
                        ),
                      ),
                      Text(
                        '${walletController.wallet?.wallet?.length ?? 0} عملية',
                        style: AppTextStyle.text14RM(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ApiResponseWidget(
                    apiResponse: walletController.walletResponse,
                    onReload: walletController.getWallet,
                    isEmpty: walletController.wallet?.wallet?.isEmpty ?? true,
                    child: RecentTransactionsWidget(
                      wallet: walletController.wallet?.wallet,
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child:
                (myAccountController.setting?.walletCardActivate == 'false' &&
                    myAccountController.setting?.paymentCardActivate == 'false')
                ? const SizedBox()
                : CustomButton(
                    text: 'walletCharging'.tr,
                    onPressed: () {
                      if (authController.profile?.email == null) {
                        NamedNavigatorImpl.push(
                          PersonalInformationScreen.routeName,
                        );
                      } else {
                        Utils.showAppBottomSheet(
                          enableDrag: true,
                          isScrollControlled: true,
                          ChangeNotifierProvider.value(
                            value: walletController,
                            child: ChargeWalletBottomSheet(
                              walletController: walletController,
                              myAccountController: myAccountController,
                            ),
                          ),
                        );
                      }
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    WalletController walletController,
    MyAccountController myAccountController,
    AuthController authController,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.greyColor.withValues(alpha: .10)),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyColor.withValues(alpha: .08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _actionItem(
            icon: Icons.receipt_long_outlined,
            title: 'سجل العمليات',
            onTap: () {},
          ),
          _actionDivider(),
          _actionItem(
            icon: Icons.swap_horiz_rounded,
            title: 'تحويل الأموال',
            onTap: () {
              Utils.showAppBottomSheet(
                enableDrag: true,
                isScrollControlled: true,
                ChangeNotifierProvider.value(
                  value: walletController,
                  child: MoneyTransferBottomSheet(
                    walletController: walletController,
                  ),
                ),
              );
            },
          ),
          _actionDivider(),
          _actionItem(
            icon: Icons.account_balance_wallet_outlined,
            title: 'شحن المحفظة',
            onTap: () {
              if (authController.profile?.email == null) {
                NamedNavigatorImpl.push(PersonalInformationScreen.routeName);
                return;
              }
              Utils.showAppBottomSheet(
                enableDrag: true,
                isScrollControlled: true,
                ChangeNotifierProvider.value(
                  value: walletController,
                  child: ChargeWalletBottomSheet(
                    walletController: walletController,
                    myAccountController: myAccountController,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _actionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.mainAppColor.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.mainAppColor, size: 27),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyle.text14MS(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionDivider() => Container(
    width: 1,
    height: 72,
    color: AppColors.greyColor.withValues(alpha: .12),
  );

  Widget _buildWalletOffer() {
    return Container(
      height: 145,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.mainAppColor,
            AppColors.mainAppColor.withValues(alpha: .72),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'اشحن محفظتك واستمتع',
                  style: AppTextStyle.text18BS().copyWith(
                    color: FasakhanstaBrand.onOrange,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'استخدم رصيدك بسهولة في طلباتك القادمة',
                  style: AppTextStyle.text14RM().copyWith(
                    color: FasakhanstaBrand.onOrange.withValues(alpha: .9),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: FasakhanstaBrand.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'فسخانستا',
                    style: AppTextStyle.text14MS().copyWith(
                      color: AppColors.mainAppColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.card_giftcard_rounded,
            color: FasakhanstaBrand.onOrange,
            size: 70,
          ),
        ],
      ),
    );
  }
}

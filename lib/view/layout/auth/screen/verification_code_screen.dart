import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:custom_timer/custom_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_form_field/custom_otp_field.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/custom_toast/custom_toast.dart';
import '../controller/auth_controller.dart';
import 'create_new_account_screen.dart';

class VerificationCodeScreen extends StatefulWidget {
  static const routeName = 'VerificationCodeScreen';

  const VerificationCodeScreen({super.key});

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeEC = TextEditingController();
  late final CustomTimerController _timerController = CustomTimerController(
    vsync: this,
    begin: const Duration(minutes: 2),
    end: const Duration(),
    initialState: CustomTimerState.reset,
    interval: CustomTimerInterval.milliseconds,
  );

  @override
  void initState() {
    _timerController.reset();
    _timerController.start();
    super.initState();
  }

  @override
  void dispose() {
    _timerController.dispose();
    _codeEC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: CustomAppBar(
          centerTitle: false,
          title: const CustomImage(
            path: AppImages.appLogo,
            type: ImageType.asset,
            height: 55,
            radius: 12,
          ),
          appBarColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 25),
              Text('verificationCode'.tr, style: AppTextStyle.text20BS()),
              18.sbH,
              Text(
                'pleaseEnterTheVerificationCodeSentToTheNumber'.tr,
                style: AppTextStyle.text18RDG(),
              ),
              const SizedBox(height: 25),
              CustomOtpField(controller: _codeEC, onCompleted: (v) {}),
              const SizedBox(height: 25),
              Center(
                child: CustomTimer(
                  controller: _timerController,
                  builder: (state, time) {
                    return Text(
                      '${time.minutes}:${time.seconds}',
                      style: AppTextStyle.text18MS(),
                    );
                  },
                ),
              ),
              15.sbH,
              Center(
                child: TextButton(
                  onPressed: () {
                    if (_timerController.state.value ==
                        CustomTimerState.finished) {
                      _timerController.reset();
                      _timerController.start();
                    } else {
                      CommonMethods.showToast(
                        message: 'Wait for the end of time'.tr,
                        type: ToastType.warning,
                        backgroundColor: FasakhanstaBrand.orange,
                      );
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        AppImages.refreshIcon,
                        colorFilter: ColorFilter.mode(
                          AppColors.whiteColor,
                          BlendMode.srcIn,
                        ),
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 150),
                      Text(
                        'Resend Code'.tr,
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontSize: 14,
                          color: FasakhanstaBrand.text,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: CustomButton(
            style: AppTextStyle.text18BW(color: FasakhanstaBrand.onOrange),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                context.read<AuthController>().codeActivate(
                      mobileCode: _codeEC.text,
                      onSuccess: () {
                        NamedNavigatorImpl.push(
                            CreateNewAccountScreen.routeName);
                      },
                    );
              }
            },
            text: 'next'.tr,
          ),
        ),
      ),
    );
  }
}

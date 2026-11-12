import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:custom_timer/custom_timer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_form_field/custom_otp_field.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../controller/auth_controller.dart';
import 'reset_password_screen.dart';

class ChangePasswordCheckCodeArguments {
  final String mobile;
  final String email;

  ChangePasswordCheckCodeArguments({required this.mobile, required this.email});
}

class ChangePasswordCheckCodeScreen extends StatefulWidget {
  static const routeName = 'ChangePasswordCheckCodeScreen';
  final ChangePasswordCheckCodeArguments? args;

  const ChangePasswordCheckCodeScreen({super.key, this.args});

  @override
  State<ChangePasswordCheckCodeScreen> createState() =>
      _ChangePasswordCheckCodeScreenState();
}

class _ChangePasswordCheckCodeScreenState
    extends State<ChangePasswordCheckCodeScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeEC = TextEditingController();

  static const _text = FasakhanstaBrand.text;
  static const _muted = FasakhanstaBrand.muted;
  static const _border = FasakhanstaBrand.border;

  late final CustomTimerController _timerController = CustomTimerController(
    vsync: this,
    begin: const Duration(minutes: 2),
    end: const Duration(),
    initialState: CustomTimerState.reset,
    interval: CustomTimerInterval.milliseconds,
  );

  @override
  void initState() {
    super.initState();
    _timerController.reset();
    _timerController.start();
  }

  @override
  void dispose() {
    _timerController.dispose();
    _codeEC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;

    return Form(
      key: _formKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(
          centerTitle: false,
          height: 70,
          title: const CustomImage(
            path: AppImages.appLogo,
            type: ImageType.asset,
            height: 52,
            radius: 12,
          ),
          appBarColor: Colors.transparent,
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 14),
                    _buildVerificationCard(context, args),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            FasakhanstaBrand.surfaceRaised,
            FasakhanstaBrand.surfaceRaised,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FasakhanstaBrand.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.mark_email_read_outlined,
              color: AppColors.mainAppColor,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'verificationCode'.tr,
                  style: AppTextStyle.text20BS().copyWith(
                    color: _text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'pleaseEnterTheVerificationCodeSentToTheEmail'.tr,
                  style: AppTextStyle.text12RG().copyWith(
                    color: _muted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(
    BuildContext context,
    ChangePasswordCheckCodeArguments? args,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if ((args?.email ?? '').isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FasakhanstaBrand.surfaceRaised,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.alternate_email_rounded,
                    color: AppColors.mainAppColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      args!.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.text12BS().copyWith(
                        color: _text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          CustomOtpField(
            controller: _codeEC,
            onCompleted: (_) => _verifyCode(),
          ),
          const SizedBox(height: 18),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: FasakhanstaBrand.surfaceRaised,
                borderRadius: BorderRadius.circular(20),
              ),
              child: CustomTimer(
                controller: _timerController,
                builder: (state, time) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 17,
                        color: AppColors.mainAppColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${time.minutes}:${time.seconds}',
                        style: AppTextStyle.text14BS().copyWith(
                          color: AppColors.mainAppColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _resendCode,
              icon: Icon(
                Icons.refresh_rounded,
                size: 19,
                color: AppColors.mainAppColor,
              ),
              label: Text(
                context.languageCode == 'ar'
                    ? 'إعادة إرسال الكود'
                    : 'Resend code',
                style: AppTextStyle.text12BS().copyWith(
                  color: AppColors.mainAppColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          CustomButton(
            style: AppTextStyle.text18BW(color: FasakhanstaBrand.onOrange),
            onPressed: _verifyCode,
            radius: 18,
            text: 'next'.tr,
          ),
        ],
      ),
    );
  }

  void _verifyCode() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    final args = widget.args;
    if (args == null) return;

    context.read<AuthController>().checkCode(
          email: args.email,
          code: _codeEC.text,
          onSuccess: () {
            Navigator.pushNamed(
              context,
              ResetPasswordScreen.routeName,
              arguments: ResetPasswordScreenArgs(
                email: args.email,
                mobile: args.mobile,
              ),
            );
          },
        );
  }

  void _resendCode() {
    final args = widget.args;
    if (args == null) return;

    if (_timerController.state.value != CustomTimerState.finished) {
      CommonMethods.showToast(
        message: context.languageCode == 'ar'
            ? 'يمكنك طلب كود جديد بعد انتهاء العداد'
            : 'You can request a new code when the timer finishes',
      );
      return;
    }

    context.read<AuthController>().forgetPassword(
          email: args.email,
          mobile: args.mobile,
          onSuccess: () {
            _codeEC.clear();
            _timerController.reset();
            _timerController.start();
          },
        );
  }
}

import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/page_container/page_container.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../account_app_bar/account_app_bar.dart';
import '../controller/my_account_controller.dart';
import '../widgets/mobile_and_email_contact_us_widget.dart';

class ContactUsScreen extends StatefulWidget {
  static const String routeName = 'ContactUsScreen';

  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen>
    with ValidationMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameEc = TextEditingController();
  final _emailEc = TextEditingController();
  final _messages = TextEditingController();

  static const _pageBackground = Colors.transparent;
  static const _text = FasakhanstaBrand.text;
  static const _muted = FasakhanstaBrand.muted;
  static const _border = FasakhanstaBrand.border;

  @override
  void dispose() {
    _nameEc.dispose();
    _emailEc.dispose();
    _messages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) {
        return MyAccountController()
          ..initialSetting()
          ..getSetting();
      },
      child: Consumer<MyAccountController>(
        builder: (context, myAccountController, _) {
          return Form(
            key: _formKey,
            child: Scaffold(
              backgroundColor: _pageBackground,
              body: PageContainer(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      24.sbH,
                      CustomAccountAppBar(title: 'contactUs'.tr),
                      const SizedBox(height: 10),
                      ApiResponseWidget(
                        apiResponse: myAccountController.settingResponse,
                        onReload: myAccountController.getSetting,
                        isEmpty: myAccountController.setting == null,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildIntroCard(context, myAccountController),
                                  const SizedBox(height: 14),
                                  MobileAndEmailContactUsWidget(
                                    myAccountController: myAccountController,
                                    mobile:
                                        myAccountController.setting?.mobile ??
                                            '',
                                    email: myAccountController.setting?.email ??
                                        '',
                                    adminId: myAccountController
                                            .setting?.adminId
                                            .toString() ??
                                        '1',
                                  ),
                                  const SizedBox(height: 14),
                                  _buildMessageCard(context),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIntroCard(
    BuildContext context,
    MyAccountController myAccountController,
  ) {
    final contactText = myAccountController.setting?.contactText?.trim() ?? '';

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: AppColors.mainAppColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'contactSupport'.tr,
                  style: AppTextStyle.text18BS().copyWith(
                    color: _text,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  contactText.isNotEmpty
                      ? contactText
                      : context.languageCode == 'ar'
                          ? 'فريق الدعم موجود لمساعدتك. اختار وسيلة التواصل المناسبة أو ابعت لنا رسالة.'
                          : 'Our support team is ready to help. Choose a contact method or send us a message.',
                  style: AppTextStyle.text12RG().copyWith(
                    color: _muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 18),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: FasakhanstaBrand.surfaceRaised,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  color: AppColors.mainAppColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.languageCode == 'ar'
                          ? 'ابعت لنا رسالة'
                          : 'Send us a message',
                      style: AppTextStyle.text16BS().copyWith(
                        color: _text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.languageCode == 'ar'
                          ? 'اكتب التفاصيل وسنتابع معك في أقرب وقت'
                          : 'Share the details and we will follow up shortly',
                      style: AppTextStyle.text11RG().copyWith(
                        color: _muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          CustomFormField(
            controller: _nameEc,
            validator: validateEmptyField,
            title: 'name'.tr,
          ),
          const SizedBox(height: 14),
          CustomFormField(
            controller: _emailEc,
            validator: validateEmptyField,
            title: 'email'.tr,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          CustomFormField(
            controller: _messages,
            validator: validateEmptyField,
            maxLines: 5,
            title: 'theMessage'.tr,
          ),
          const SizedBox(height: 18),
          CustomButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              if (!_formKey.currentState!.validate()) return;

              context.read<MyAccountController>().storeContact(
                    name: _nameEc.text.trim(),
                    email: _emailEc.text.trim(),
                    message: _messages.text.trim(),
                    onSuccess: () {
                      Navigator.pop(context);
                    },
                  );
            },
            text: 'send'.tr,
          ),
        ],
      ),
    );
  }
}

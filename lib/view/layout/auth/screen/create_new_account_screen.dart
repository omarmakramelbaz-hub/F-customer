import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/custom_select/custom_select_item.dart';
import '../../../custom_widgets/custom_select/custom_single_select.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../controller/auth_controller.dart';
import 'share_location_screen.dart';

class CreateNewAccountScreen extends StatefulWidget {
  static const routeName = 'CreateNewAccountScreen';
  const CreateNewAccountScreen({super.key});

  @override
  State<CreateNewAccountScreen> createState() => _CreateNewAccountScreenState();
}

class _CreateNewAccountScreenState extends State<CreateNewAccountScreen>
    with ValidationMixin {
  int? _country;
  final _formKey = GlobalKey<FormState>();
  final _nameEc = TextEditingController();
  final _emailEc = TextEditingController();

  final nameFocusNode = FocusNode();
  final emailFocusNode = FocusNode();

  @override
  void dispose() {
    _nameEc.dispose();
    _emailEc.dispose();
    nameFocusNode.dispose();
    emailFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) {
        return AuthController()
          ..initialArea()
          ..getArea();
      },
      child: Consumer<AuthController>(
        builder: (context, authController, _) {
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
              body: ApiResponseWidget(
                apiResponse: authController.areaResponse,
                onReload: () => authController.getArea(),
                isEmpty: authController.area.isEmpty,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),
                      Text(
                        'createANewAccount'.tr,
                        style: AppTextStyle.text20BS(),
                      ),
                      18.sbH,
                      Text(
                        'completeTheInformationToCreateYourAccount'.tr,
                        style: AppTextStyle.text18RDG(),
                      ),
                      const SizedBox(height: 35),
                      CustomFormField(
                        validator: validateEmptyField,
                        controller: _nameEc,
                        title: 'name'.tr,
                        focusNode: nameFocusNode,
                        onFieldSubmitted: (p0) {
                          FocusScope.of(context).requestFocus(emailFocusNode);
                        },
                      ),
                      const SizedBox(height: 25),
                      CustomFormField(
                        controller: _emailEc,
                        validator: validateEmptyField,
                        keyboardType: TextInputType.emailAddress,
                        title: 'email'.tr,
                        focusNode: emailFocusNode,
                        onFieldSubmitted: (p0) {
                          emailFocusNode.unfocus();
                        },
                      ),
                      const SizedBox(height: 25),
                      CustomSingleSelect(
                        validator: validateEmptyDropDown,
                        apiResponse: authController.areaResponse,
                        onReload: () => authController.getArea(),
                        value: _country ??
                            (authController.area.isNotEmpty
                                ? authController.area[0].id ?? 0
                                : 0),
                        onChanged: (value) {
                          setState(() {
                            _country = value;
                          });
                        },
                        title: 'country'.tr,
                        items: authController.area
                            .map(
                              (e) => CustomSelectItem(
                                value: e.id,
                                name: e.title ?? '',
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 150),
                      CustomButton(
                        style: AppTextStyle.text18BW(),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<AuthController>().updateUserInfo(
                                  name: _nameEc.text,
                                  email: _emailEc.text,
                                  id: _country ??
                                      authController.area.first.id ??
                                      0,
                                  onSuccess: () {
                                    NamedNavigatorImpl.push(
                                      ShareLocationScreen.routeName,
                                    );
                                  },
                                  onHaveIdANDToken: (id, token) {
                                    context.read<PusherController>().initPusher(
                                          channelName: 'private-user.$id',
                                          userId: id,
                                          token: token,
                                        );
                                  },
                                );
                          }
                          // NavigatorMethods.pushNamed(
                          //   context,
                          //   ShareLocationScreen.routeName,
                          // );
                        },
                        text: 'createAnAccount'.tr,
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
}

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../auth/screen/login_screen.dart';
import '../controller/on_boarding_controller.dart';
import '../tap/f_on_boarding_tab.dart';

class OnBoardingScreen extends StatefulWidget {
  static const String routeName = 'onBoardingScreen';
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  late PageController _controller;
  int _page = 0;
  @override
  void initState() {
    super.initState();
    _controller = PageController();
    HiveMethods.updateFirstTime();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) {
        return OnBoardingController()
          ..initialSplashes()
          ..getSplashes();
      },
      child: Consumer<OnBoardingController>(
        builder: (context, onBoardingController, _) {
          return Scaffold(
            appBar: CustomAppBar(
              height: 130,
              appBarColor: Colors.transparent,
              title: const CustomImage(
                path: AppImages.appLogo,
                type: ImageType.asset,
                height: 60,
                radius: 12,
              ),
              leading: Center(
                child: TextButton(
                  onPressed: () {
                    NamedNavigatorImpl.push(clean: true, LoginScreen.routeName);
                  },
                  child: Text('skip'.tr, style: AppTextStyle.text16MS()),
                ),
              ),
              leadingWidth: 70,
            ),
            body: ApiResponseWidget(
              apiResponse: onBoardingController.splashesResponse,
              onReload: onBoardingController.getSplashes,
              isEmpty: onBoardingController.splashes.isEmpty,
              child: PageView(
                controller: _controller,
                children: [
                  ...List.generate(onBoardingController.splashes.length, (
                    index,
                  ) {
                    return FOnBoardingTab(
                      index: index,
                      controller: _controller,
                      splashModel: onBoardingController.splashes[index],
                      length: onBoardingController.splashes.length,
                    );
                  }),
                ],
                onPageChanged: (page) {
                  setState(() {
                    _page = page;
                    log(_page.toString());
                    log(onBoardingController.splashes.length.toString());
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

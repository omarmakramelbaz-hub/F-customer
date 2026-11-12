import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../bottom_navigation/bottom_navigation_bar_screen.dart';

class ShareLocationScreen extends StatefulWidget {
  static const routeName = 'ShareLocationScreen';
  const ShareLocationScreen({super.key});

  @override
  State<ShareLocationScreen> createState() => _ShareLocationScreenState();
}

class _ShareLocationScreenState extends State<ShareLocationScreen> {
  // Future<void> _checkPermission() async {
  //   LocationPermission permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     log("Location permissions are denied");
  //   } else if (permission == LocationPermission.deniedForever) {
  //     log('Location permissions are permanently denied, we cannot request permissions.');
  //   } else {
  //     log('Location permission granted.');
  //   }
  // }

  Future<void> _requestPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      log('Location permission granted.');
    } else {
      log('Location permissions are denied');
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      log('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        log('Location permissions are denied');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      log(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    log('${position.latitude} ${position.longitude}');
    HiveMethods.updateLan(position.longitude);
    HiveMethods.updateLat(position.latitude);
  }

  void navigateToNextScreen() {
    NamedNavigatorImpl.push(clean: true, BottomNavigationBarScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Text(
              'allowSharingOfYourLocation'.tr,
              style: AppTextStyle.text20BS(),
            ),
            18.sbH,
            Text(
              'sharingYourLocationIsCompletelySafeAndIsNotSharedWithAnyoneElse'
                  .tr,
              style: AppTextStyle.text18RDG(),
            ),
            18.sbH,
            SvgPicture.asset(AppImages.shareLocationIcon),
            20.sbH,
            CustomButton(
              onPressed: () async {
                await _requestPermission();
                await _determinePosition();
                navigateToNextScreen();
              },
              style: AppTextStyle.text18BW(),
              text: 'allowSharing'.tr,
            ),
            const SizedBox(height: 15),
            Center(
              child: TextButton(
                onPressed: () {
                  NamedNavigatorImpl.push(
                    clean: true,
                    BottomNavigationBarScreen.routeName,
                  );
                },
                child: Text('skipForNow'.tr, style: AppTextStyle.text18RS()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

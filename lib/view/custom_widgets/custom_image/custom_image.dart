import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../helpers/images/app_images.dart';
import '../../../helpers/routes/app_routers_import.dart';
import '../../../helpers/theme/app_colors.dart';
import '../zoom_image/zoom_image_screen.dart';

class CustomImage extends StatelessWidget {
  /// path can be (url, file path, asset path)
  final String path;
  final ImageType type;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit? fit;
  final Color? color;
  final bool hasZoom;

  const CustomImage({
    super.key,
    required this.path,
    required this.type,
    this.width,
    this.height,
    this.radius = 0,
    this.fit,
    this.hasZoom = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hasZoom
          ? () {
              NamedNavigatorImpl.push(
                ZoomImageScreen.routeName,
                arguments: ZoomImageArgs(path: path, type: type),
              );
            }
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: _ImageBuild(
          type: type,
          radius: radius,
          path: path,
          fit: fit,
          height: height,
          width: width,
          color: color,
        ),
      ),
    );
  }
}

enum ImageType { network, file, asset, svg }

class _ImageBuild extends StatelessWidget {
  final ImageType type;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit? fit;
  final String path;
  final Color? color;

  const _ImageBuild({
    required this.type,
    this.width,
    this.height,
    required this.radius,
    this.fit,
    required this.path,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ImageType.network:
        return CachedNetworkImage(
          imageUrl: path,
          fit: fit,
          width: width,
          height: height,
          placeholder: (context, url) =>
              CupertinoActivityIndicator(color: AppColors.mainAppColor),
          errorWidget: (context, url, error) {
            try {
              debugPrint('Network Image Error: $error, URL: $url');

              if (error is HttpException && error.message.contains('404')) {
                debugPrint('404 error for network image: $url');
              }

              return Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: FasakhanstaBrand.surfaceRaised,
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Image.asset(AppImages.appLogo, fit: fit),
              );
            } catch (e) {
              return Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: FasakhanstaBrand.surfaceRaised,
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Image.asset(AppImages.appLogo, fit: fit),
              );
            }
          },
        );

      case ImageType.file:
        return Image(
          image: FileImage(File(path)),
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, url, error) {
            debugPrint('File Image Error: $error');

            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: FasakhanstaBrand.surfaceRaised,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Image.asset(AppImages.appLogo, fit: fit),
            );
          },
        );

      case ImageType.asset:
        return Image(
          image: AssetImage(path),
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, url, error) {
            debugPrint('Asset Image Error: $error');

            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: FasakhanstaBrand.surfaceRaised,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Image.asset(AppImages.appLogo, fit: fit),
            );
          },
        );

      case ImageType.svg:
        final lowerPath = path.toLowerCase();
        final isRasterAsset = lowerPath.endsWith('.png') ||
            lowerPath.endsWith('.jpg') ||
            lowerPath.endsWith('.jpeg') ||
            lowerPath.endsWith('.webp');

        if (isRasterAsset) {
          return Image.asset(
            path,
            fit: fit ?? BoxFit.contain,
            width: width,
            height: height,
          );
        }

        return SvgPicture.asset(
          path,
          fit: fit ?? BoxFit.contain,
          width: width,
          height: height,
          colorFilter:
              color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
          placeholderBuilder: (context) =>
              CupertinoActivityIndicator(color: AppColors.mainAppColor),
        );
    }
  }
}

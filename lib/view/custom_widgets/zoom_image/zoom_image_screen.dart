import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:photo_view/photo_view.dart';

import '../custom_app_bar/custom_app_bar.dart';
import '../custom_image/custom_image.dart';
import '../custom_loading/custom_loading.dart';

class ZoomImageArgs {
  final String path;
  final ImageType type;

  const ZoomImageArgs({required this.path, required this.type});
}

class ZoomImageScreen extends StatefulWidget {
  final ZoomImageArgs args;
  const ZoomImageScreen({super.key, required this.args});

  static const String routeName = 'ZoomImageScreen';

  @override
  State<ZoomImageScreen> createState() => _ZoomImageScreenState();
}

class _ZoomImageScreenState extends State<ZoomImageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(centerTitle: false, automaticallyImplyLeading: true),
      body: PhotoView(
        imageProvider: _imageProvider(),
        loadingBuilder: (context, event) {
          return const Center(child: CustomLoading());
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: FasakhanstaBrand.surfaceRaised,
          );
        },
      ),
    );
  }

  ImageProvider? _imageProvider() {
    switch (widget.args.type) {
      case ImageType.network:
        return NetworkImage(widget.args.path);
      case ImageType.file:
        return FileImage(File(widget.args.path));
      case ImageType.asset:
        return AssetImage(widget.args.path);
      case ImageType.svg:
        return Svg(widget.args.path);
    }
  }
}

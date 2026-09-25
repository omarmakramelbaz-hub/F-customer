import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/date_methods.dart';
import '../../../../helpers/utils/url_launcher_methods.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/global_widgets/connect_support_widget.dart';
import '../../chat/screen/chat_screen.dart';
import '../../map/utils/map_services.dart';
import '../controller/request_delegate_controller.dart';

class TrackingDelegateOrderArgs {
  final int id;
  final VoidCallback? onSuccess;
  TrackingDelegateOrderArgs({required this.id, this.onSuccess});
}

class TrackingDelegateOrderScreen extends StatefulWidget {
  final TrackingDelegateOrderArgs args;
  static const routeName = 'TrackingDelegateOrderScreen';
  const TrackingDelegateOrderScreen({super.key, required this.args});
  @override
  State<TrackingDelegateOrderScreen> createState() => _TrackingDelegateOrderScreenState();
}

class _TrackingDelegateOrderScreenState extends State<TrackingDelegateOrderScreen> {
  late RequestDelegateController requestDelegateController;
  late MapServices mapServices;
  LatLng? origin;
  LatLng? destination;
  late GoogleMapController googleMapController;
  String? _mapStyle;

  Set<Polyline> polyLines = {};
  Set<Marker> markers = {};
  bool isMapReady = false;
  Timer? _liveTimer;
  bool _offerDialogOpen = false; // New flag for checking if map is ready

  void initMapStyle() async {
    var mapStyle = await DefaultAssetBundle.of(context).loadString('assets/map_styles/dark_map_style.json');
    setState(() {
      _mapStyle = mapStyle;
    });
  }

  @override
  void initState() {
    initMapStyle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestDelegateController = Provider.of<RequestDelegateController>(context, listen: false);
      Provider.of<RequestDelegateController>(context, listen: false).initialDelegateOrderDetails();

      Provider.of<RequestDelegateController>(context, listen: false).getDelegateOrderDetails(id: widget.args.id).then((
        value,
      ) async {
        mapServices = MapServices();
        final orderDetails = requestDelegateController.delegateOrderDetails;

        // Set origin and destination
        origin = LatLng(double.parse(orderDetails?.fromLat ?? '0.0'), double.parse(orderDetails?.fromLng ?? '0.0'));
        destination = LatLng(double.parse(orderDetails?.toLat ?? '0.0'), double.parse(orderDetails?.toLng ?? '0.0'));

        // Ensure the coordinates are valid before proceeding
        if (origin!.latitude != 0.0 && destination!.latitude != 0.0) {
          // Get the polyline points
          // var points = await mapServices.getRouteData(
          //   originFrom: origin!,
          //   desintation: destination!,
          // );

          // Add polyline for the route
          setState(() {
            // polyLines.add(
            //   Polyline(
            //     polylineId: const PolylineId('route'),
            //     points: points,
            //     color: Colors.orange,
            //     width: 5,
            //   ),
            // );

            // Add markers for origin and destination
            markers.add(Marker(markerId: const MarkerId('origin'), position: origin!));
            markers.add(Marker(markerId: const MarkerId('destination'), position: destination!));
            setState(() {});
          });
        }
        _startLiveOrderRefresh();
        await requestDelegateController.getAcceptedDelegate(delegateOrderId: widget.args.id);
        if (mounted) _showRevisedOfferIfNeeded();
      });
    });
    super.initState();
  }

  void _startLiveOrderRefresh() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      await requestDelegateController.getDelegateOrderDetails(id: widget.args.id);
      await requestDelegateController.getAcceptedDelegate(delegateOrderId: widget.args.id);
      if (mounted) _showRevisedOfferIfNeeded();
    });
  }

  Future<void> _showRevisedOfferIfNeeded() async {
    final offer = requestDelegateController.acceptedDelegate?.activeOffer;
    if (_offerDialogOpen || offer == null || offer.status != 'price_revision' || !mounted) return;
    _offerDialogOpen = true;
    final ar = context.languageCode == 'ar';
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(ar ? 'عرض سعر جديد من المندوب' : 'New price offer'),
        content: Text(ar
            ? 'المندوب اقترح سعر توصيل جديد بقيمة ${offer.price} جنيه. لن يتغير سعر الطلب إلا بعد موافقتك.'
            : 'The driver proposed a new fare of ${offer.price} EGP. Your fare changes only if you accept.'),
        actions: [
          TextButton(
            onPressed: () async {
              final ok = await requestDelegateController.respondToRevisedOffer(orderId: widget.args.id, status: 'declined');
              if (ok && dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(ar ? 'رفض' : 'Decline'),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await requestDelegateController.respondToRevisedOffer(orderId: widget.args.id, status: 'accepted');
              if (ok && dialogContext.mounted) Navigator.pop(dialogContext);
              if (ok && mounted) {
                await requestDelegateController.getDelegateOrderDetails(id: widget.args.id);
              }
            },
            child: Text(ar ? 'قبول السعر الجديد' : 'Accept new fare'),
          ),
        ],
      ),
    );
    _offerDialogOpen = false;
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          widget.args.onSuccess?.call();
        }
      },
      child: Consumer<RequestDelegateController>(
        builder: (context, requestDelegateController, _) {
          // If origin or destination are null, show a loading indicator
          if (origin == null || destination == null) {
            return const Center(
              child: CircularProgressIndicator(), // Or any other loading widget
            );
          }

          final orderDetails = requestDelegateController.delegateOrderDetails;

          return ApiResponseWidget(
            apiResponse: requestDelegateController.delegateOrderDetailsApiResponse,
            onReload: () => requestDelegateController.getDelegateOrderDetails(id: widget.args.id),
            isEmpty: orderDetails == null,
            child: Container(
              color: AppColors.blackColor,
              child: Scaffold(
                backgroundColor: AppColors.blackColor,
                appBar: CustomAppBar(
                  appBarColor: AppColors.blackColor,
                  title: Text(
                    DateMethods.formatDateToArabic(orderDetails?.createdAt ?? ''),
                    style: AppTextStyle.text18BS().copyWith(color: AppColors.whiteColor),
                  ),
                ),
                body: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              20.sbH,
                              _buildMap(),
                              20.sbH,
                              Row(
                                children: [
                                  const CustomImage(path: AppImages.radioToIcon, type: ImageType.svg),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      orderDetails?.fromAddress ?? '',
                                      style: AppTextStyle.text16MS().copyWith(color: AppColors.whiteColor),
                                    ),
                                  ),
                                ],
                              ),
                              20.sbH,
                              Row(
                                children: [
                                  const CustomImage(path: AppImages.radioFromIcon, type: ImageType.svg),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      orderDetails?.toAddress ?? '',
                                      style: AppTextStyle.text16MS().copyWith(color: AppColors.whiteColor),
                                    ),
                                  ),
                                ],
                              ),
                              10.sbH,
                              if (orderDetails?.delegateId != null) ...[
                                Divider(color: AppColors.darkGreyColor),
                                10.sbH,
                                Row(
                                  children: [
                                    CustomImage(
                                      path: orderDetails?.delegateLogo == null
                                          ? AppImages.delegateRDIcon
                                          : orderDetails?.delegateLogo ?? '',
                                      type: orderDetails?.delegateLogo == null ? ImageType.svg : ImageType.network,
                                      width: 45,
                                      height: 45,
                                      radius: 30,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        orderDetails?.delegateName ?? '',
                                        style: AppTextStyle.text16MS().copyWith(color: AppColors.whiteColor),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        UrlLauncherMethods.makePhoneCall(
                                          orderDetails?.delegateMobile ?? '',
                                        );
                                      },
                                      child: Card(
                                        elevation: 10,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        child: CircleAvatar(
                                          radius: 20,
                                          backgroundColor: AppColors.whiteColor,
                                          child: CustomImage(
                                            path: AppImages.callIcon,
                                            type: ImageType.svg,
                                            color: AppColors.blackColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (orderDetails?.delegateFcmId != null) ...[
                                      GestureDetector(
                                        onTap: () {
                                          NamedNavigatorImpl.push(
                                            ChatScreen.routeName,
                                            arguments: ChatScreenArgs(
                                              senderDeviceToken: orderDetails?.userFcmId ?? '',
                                              accountType: 'vendor',
                                              isVendor: false,
                                              vendorDeviceToken: requestDelegateController
                                                      .delegateOrderDetails?.resturantVendorDeviceToken ??
                                                  '',
                                              receiverDeviceToken: orderDetails?.delegateFcmId ?? '',
                                              senderName: orderDetails?.userName ?? '',
                                              receiverName: orderDetails?.delegateName ?? '',
                                              orderId: "VD${orderDetails?.id ?? ""}",
                                            ),
                                          );
                                        },
                                        child: Card(
                                          elevation: 10,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          child: CircleAvatar(
                                            radius: 20,
                                            backgroundColor: AppColors.whiteColor,
                                            child: CustomImage(
                                              path: AppImages.chatIcon,
                                              type: ImageType.svg,
                                              color: AppColors.blackColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                              10.sbH,
                              Divider(color: AppColors.darkGreyColor),
                              10.sbH,
                              Text(
                                'orderDetails'.tr,
                                style: AppTextStyle.text16MS().copyWith(color: AppColors.whiteColor),
                              ),
                              10.sbH,
                              Text(
                                orderDetails?.description ?? '',
                                style: AppTextStyle.text16MS().copyWith(color: AppColors.whiteColor),
                              ),
                              10.sbH,
                              Divider(color: AppColors.darkGreyColor),
                              10.sbH,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'deliverCost'.tr,
                                    style: AppTextStyle.text16MS().copyWith(color: AppColors.whiteColor),
                                  ),
                                  Text(
                                    'pound'.tr.replaceAll(
                                          '{}',
                                          '${orderDetails?.actualPrice}',
                                        ),
                                    style: AppTextStyle.text16MS().copyWith(color: AppColors.whiteColor),
                                  ),
                                ],
                              ),
                              10.sbH,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Text(
                                      'paymentMethod'.tr,
                                      style: AppTextStyle.text16BS().copyWith(color: AppColors.whiteColor),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    height: 24,
                                    width: 5,
                                    decoration: BoxDecoration(
                                      color: AppColors.mainAppColor,
                                      borderRadius: BorderRadius.horizontal(
                                        left: context.languageCode == 'ar'
                                            ? const Radius.circular(5)
                                            : const Radius.circular(0),
                                        right: context.languageCode == 'ar'
                                            ? const Radius.circular(0)
                                            : const Radius.circular(5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  CustomImage(
                                    height: 18,
                                    path: orderDetails?.paymentType == 'cash'
                                        ? AppImages.cashIcon
                                        : orderDetails?.paymentType == 'online'
                                            ? AppImages.visaIcon
                                            : orderDetails?.paymentType == 'v_cash'
                                                ? AppImages.vfCash
                                                : orderDetails?.paymentType == 'wallet'
                                                    ? AppImages.payWalletIcon.tr
                                                    : '',
                                    type: ImageType.svg,
                                    color: AppColors.mainAppColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    orderDetails?.paymentType == 'cash'
                                        ? 'cash'.tr
                                        : orderDetails?.paymentType == 'online'
                                            ? 'visa'.tr
                                            : orderDetails?.paymentType == 'v_cash'
                                                ? 'vfCash'.tr
                                                : orderDetails?.paymentType == 'wallet'
                                                    ? 'appWallet'.tr
                                                    : '',
                                    style: AppTextStyle.text16BM(),
                                  ),
                                ],
                              ),
                              if (orderDetails?.status == 'accepted')
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: CustomButton(
                                    text: 'cancelOrder'.tr,
                                    onPressed: () {
                                      requestDelegateController.cancelOrder(
                                        orderId: orderDetails!.id!,
                                        onSuccess: () {
                                          NamedNavigatorImpl.pop();
                                        },
                                      );
                                    },
                                  ),
                                ),
                              30.sbH,
                            ],
                          ),
                        ),
                      ),
                    ),
                    const ConnectSupportWidget(isDark: true),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  ClipRRect _buildMap() {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(15)),
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: origin!, // Use the origin as the target
            zoom: 16,
          ),
          zoomControlsEnabled: false,
          markers: markers,
          polylines: polyLines,
          style: _mapStyle,
          onMapCreated: (GoogleMapController controller) {
            googleMapController = controller;
            // googleMapController.setMapStyle(_mapStyle);
            markers.add(Marker(markerId: const MarkerId('origin'), position: origin!));

            markers.add(Marker(markerId: const MarkerId('destination'), position: destination!));

            setState(() {
              isMapReady = true; // Set flag when map is ready
            });

            // Update the camera to show both origin and destination
            googleMapController.animateCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(
                    origin!.latitude < destination!.latitude ? origin!.latitude : destination!.latitude,
                    origin!.longitude < destination!.longitude ? origin!.longitude : destination!.longitude,
                  ),
                  northeast: LatLng(
                    origin!.latitude > destination!.latitude ? origin!.latitude : destination!.latitude,
                    origin!.longitude > destination!.longitude ? origin!.longitude : destination!.longitude,
                  ),
                ),
                100.0,
              ),
            );
          },
        ),
      ),
    );
  }
}

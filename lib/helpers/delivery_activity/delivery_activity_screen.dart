import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../extensions/extensions.dart';
import '../networking/api_helper.dart';
import '../notification_helper/notification_helper.dart';
import 'delivery_provider.dart';

class DeliveryActivityScreen extends StatefulWidget {
  const DeliveryActivityScreen({super.key});

  @override
  State<DeliveryActivityScreen> createState() => _DeliveryActivityScreenState();
}

class _DeliveryActivityScreenState extends State<DeliveryActivityScreen> {
  @override
  void initState() {
    super.initState();

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final liveActivitiesController = Provider.of<DeliveryProvider>(context, listen: false);
    //   liveActivitiesController.init(5657).whenComplete(() {
    //     liveActivitiesController.startDelivery(orderStatus: 'Preparing');
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeliveryProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (provider.deliveryModel != null) ...[
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Fasakhansta',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          10.sbH,
                          Text(
                            provider.deliveryModel?.orderStatus ?? '',
                            style: const TextStyle(
                              fontSize: 24,
                              color: FasakhanstaBrand.orange,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          10.sbH,
                          LinearProgressIndicator(
                            value: _getProgress(
                              provider.deliveryModel?.orderStatus,
                            ),
                            color: Colors.orange,
                            backgroundColor: FasakhanstaBrand.orange
                                .withOpacity(0.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  20.sbH,
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _btn(provider, 'Preparing'),
                      _btn(provider, 'Picked Up'),
                      _btn(provider, 'Delivered'),
                    ],
                  ),
                  20.sbH,
                  ElevatedButton.icon(
                    onPressed: () => provider.stopDelivery(),
                    icon: const Icon(Icons.stop),
                    label: const Text('End Delivery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FasakhanstaBrand.dangerTint,
                      foregroundColor: FasakhanstaBrand.text,
                    ),
                  ),
                ] else
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => provider
                          .init(5657)
                          .whenComplete(
                            () => provider.startDelivery('Preparing'),
                          ),
                      icon: const Icon(Icons.local_pizza),
                      label: const Text('Start Delivery Order'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseNotifications.getToken();
                    final message = await provider.checkLiveActivitiesSupport();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(message)));
                    }
                    final token = FirebaseNotifications.fcmToken ?? '';
                    if (token.trim().isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'FCM token is empty. Check APNS registration and permissions.',
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    await ApiHelper.instance.sendNotification(
                      deviceToken: token,
                      titleName: 'Live Activities Support',
                      body: 'Your device',
                      data: {
                        'notification_type': 'live_activity',
                        'order_status': 'on_the_way',
                      },
                    );
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Check Live Activity Support'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ElevatedButton _btn(DeliveryProvider provider, String status) {
    return ElevatedButton(
      onPressed: () => provider.updateStatus(status),
      child: Text(status),
    );
  }

  double _getProgress(String? status) {
    switch (status) {
      case 'Preparing':
        return 0.25;
      case 'Picked Up':
        return 0.5;
      case 'Delivered':
        return 1.0;
      default:
        return 0.0;
    }
  }
}

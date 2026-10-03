import 'package:flutter/material.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';
import '../model/notifications_model.dart';

class NotificationsController extends ChangeNotifier {
  void addNotificationToTop(NotificationsModel notification) {
    if (HiveMethods.isNotificationHidden(notification.id)) return;
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void initialNotifications() {
    _notificationsResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _notifications = [];
    notifyListeners();
  }

  ApiResponse _notificationsResponse =
      ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get notificationsResponse => _notificationsResponse;

  List<NotificationsModel> _notifications = [];
  List<NotificationsModel> get notifications => _notifications;
  bool _isFetching = false;

  Future<void> getNotifications() async {
    if (_isFetching) return;
    _isFetching = true;

    final hadData = _notifications.isNotEmpty;
    final previousResponse = _notificationsResponse;

    if (!hadData) {
      _notificationsResponse =
          ApiResponse(state: ResponseState.loading, data: null);
      notifyListeners();
    }

    final response =
        await ApiHelper.instance.get(Urls.userNotifications);

    if (response.state == ResponseState.complete) {
      _notificationsResponse = response;
      final dynamic rawData = response.data['data'];
      final Iterable iterable =
          rawData is Iterable ? rawData : const [];
      final hiddenIds = HiveMethods.getHiddenNotificationIds();

      _notifications = iterable
          .map((e) => NotificationsModel.fromJson(e))
          .where((notification) {
            final id = notification.id;
            return id == null || id.isEmpty || !hiddenIds.contains(id);
          })
          .toList();
    } else if (!hadData) {
      _notificationsResponse = response;
    } else {
      _notificationsResponse = previousResponse;
    }

    _isFetching = false;
    notifyListeners();
  }

  Future<void> clearAllNotifications() async {
    final ids = _notifications
        .map((notification) => notification.id)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    if (ids.isNotEmpty) {
      await HiveMethods.hideNotificationIds(ids);
    }

    _notifications = [];
    _notificationsResponse =
        ApiResponse(state: ResponseState.complete, data: {'data': []});
    notifyListeners();
  }
}

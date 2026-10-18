import 'dart:convert';

// import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class PusherController with ChangeNotifier {
  late PusherChannelsFlutter _pusher;

  final String appId = '2002846';
  final String apiKEY = '0f818db2b7622218a22a';
  final String apiCLUSTER = 'mt1';
  final Map<String, List<void Function(PusherEvent event)>> _eventListeners = {};

  PusherController() {
    _pusher = PusherChannelsFlutter.getInstance();
  }

  Future<void> initPusher({
    // required void Function(PusherEvent event) onEvent,
    required String channelName,
    required int userId,
    required String token,
  }) async {
    try {
      await _pusher.init(
        apiKey: apiKEY,
        cluster: apiCLUSTER,
        onConnectionStateChange: (currentState, previousState) {
          // log('Connection State Change: $previousState → $currentState');

          if (currentState == 'CONNECTED') {
            // log('Pusher connected. Fetching socket ID...');

            _subscribeToChannel(channelName, userId, token);
            subscribeToPublicChannel('resturant.updated');
            subscribeToPublicChannel('product.updated');
            subscribeToPublicChannel('coupon.wheel.updated');
          }
        },
        onError: (message, code, e) {
          // log('Error: $message, Code: $code, Exception: $e');
        },
        onEvent: _handleEvent,
        onSubscriptionError: onSubscriptionError,
        onDecryptionFailure: onDecryptionFailure,
        onMemberAdded: onMemberAdded,
        onMemberRemoved: onMemberRemoved,
        // logToConsole: true,
        onAuthorizer: (channelName, socketId, options) async {
          return await _authenticatePrivateChannel(channelName, userId, socketId, token);
        },
      );

      // log('Connecting to Pusher...');

      await _pusher.connect();
      _subscribeToChannel(channelName, userId, token);
      subscribeToPublicChannel('resturant.updated');
      subscribeToPublicChannel('product.updated');
      subscribeToPublicChannel('coupon.wheel.updated');
    } catch (e) {
      // log('Error during Pusher initialization: $e');
    }
  }

  Future<void> subscribeToPublicChannel(String channelName) async {
    try {
      // log('Subscribing to public channel: $channelName');
      await _pusher.subscribe(channelName: channelName);
      // log('Successfully subscribed to public channel: $channelName');
    } catch (e) {
      // log('Error during public channel subscription: $e');
    }
  }

  void _handleEvent(PusherEvent event) {
    // log('Event received: ${event.eventName}');
    // log('Event data: ${event.data}');
    // if (event.eventName == "") {
    //   notifyListeners(); // Notify all listeners of `PusherController`
    // }
    // Notify listeners for the specific event
    if (_eventListeners.containsKey(event.eventName)) {
      for (var listener in _eventListeners[event.eventName]!) {
        listener(event);
      }
    }
  }

  void addEventListener(String eventName, void Function(PusherEvent) listener) {
    if (!_eventListeners.containsKey(eventName)) {
      _eventListeners[eventName] = [];
    }
    _eventListeners[eventName]!.add(listener);
  }

  void removeEventListener(String eventName, void Function(PusherEvent) listener) {
    _eventListeners[eventName]?.remove(listener);
    if (_eventListeners[eventName]?.isEmpty ?? true) {
      _eventListeners.remove(eventName);
    }
  }

  Future<String?> _fetchSocketId() async {
    String? socketId;
    int retryCount = 0;

    while (socketId == null && retryCount < 5) {
      socketId = await _pusher.getSocketId();
      retryCount++;
    }

    if (socketId == null) {
      // log('Failed to fetch Socket ID after multiple attempts.');
    }
    return socketId;
  }

  Future<void> _subscribeToChannel(String? channelName, int? userId, String? token) async {
    try {
      var socketId = await _fetchSocketId();
      if (socketId == null) {
        // log('Socket ID is null. Cannot proceed with subscription.');
        return;
      }

      // log('Attempting to subscribe to channel: $channelName with Socket ID: $socketId');

      if (channelName != null && channelName.startsWith('private-')) {
        final authResponse = await _authenticatePrivateChannel(channelName, userId!, socketId, token!);

        if (authResponse != null && authResponse['auth'] != null) {
          await _pusher.subscribe(channelName: channelName);
          // log('Successfully subscribed to private channel: $channelName');
        } else {
          // log('Authentication failed. Could not subscribe to private channel: $channelName');
        }
      } else {
        await _pusher.subscribe(channelName: channelName ?? '');
        // log('Successfully subscribed to public channel: $channelName');
      }
    } catch (e) {
      // log('Error during channel subscription: $e');
    }
  }

  Future<Map<String, dynamic>?> _authenticatePrivateChannel(
    String channelName,
    int userId,
    String socketId,
    String token,
  ) async {
    try {
      // log('Authenticating private channel: $channelName with socket ID: $socketId');

      // // Replace with your token retrieval logic

      final url = Uri.parse('https://fasakhaninja.com/api/pusher/auth');
      final response = await http.post(
        url,
        body: {'channel_name': channelName, 'socket_id': socketId},
        headers: {'Accept': 'application/json', if (token != '') 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        return responseJson.containsKey('auth') ? {'auth': responseJson['auth']} : null;
      } else {
        // log('Authentication failed. Status: ${response.statusCode}, Body: ${response.body}');
        return null;
      }
    } catch (e) {
      // log('Error during private channel authentication: $e');
      return null;
    }
  }

  void disconnectPusher() {
    // log('Disconnecting Pusher...');
    _pusher.disconnect();
  }

  // Additional helper methods if needed
  Future<void> unsubscribeFromChannel(String channelName) async {
    try {
      await _pusher.unsubscribe(channelName: channelName);
      // log('Unsubscribed from channel: $channelName');
    } catch (e) {
      // log('Error during unsubscription: $e');
    }
  }

  void reconnectPusher() {
    // log('Reconnecting Pusher...');
    _pusher.connect();
  }

  // Callback Methods
  void onError(String message, int? code, dynamic e) {
    // log('Error: $message, Code: $code, Exception: $e');
  }

  void onSubscriptionSucceeded(String channelName, dynamic data) {
    // log('Successfully subscribed to channel: $channelName with data: $data');
  }

  void onSubscriptionError(String message, dynamic e) {
    // log('❌ Subscription Error: $message, Exception: $e');
  }

  void onDecryptionFailure(String event, String reason) {
    // log('Decryption failure on event $event: $reason');
  }

  void onMemberAdded(String channelName, PusherMember member) {
    // log('Member Added: Channel: $channelName, User: $member');
  }

  void onMemberRemoved(String channelName, PusherMember member) {
    // log('Member Removed: Channel: $channelName, User: $member');
  }
}

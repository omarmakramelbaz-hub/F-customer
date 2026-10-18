import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../helpers/networking/api_helper.dart';
import '../model/admin_chat_model.dart';

class AdminChatController extends ChangeNotifier {
  String? roomId;
  // String? _senderId;
  // String? _receiverId;

  Stream<QuerySnapshot<Map<String, dynamic>>>? chatStream;
  final _firestore = FirebaseFirestore.instance;

  void initial(String senderId, String receiverId) {
    String sortedRoomId =
        (int.parse(senderId) < int.parse(receiverId)) ? 'room_${senderId}_$receiverId' : 'room_${receiverId}_$senderId';

    roomId = sortedRoomId;
    chatStream = _firestore.collection('DashboardChat').doc(roomId.toString()).collection('messages').snapshots();
    log(roomId.toString());
    notifyListeners();
  }

  Future<void> send(
    String receiverName,
    String senderName,
    String text,
    String senderId,
    String receiverId,
    String adminDeviceToken,
  ) async {
    final time = DateTime.now();
    var uuid = const Uuid(); // Generate unique message IDs

    // Ensure consistent roomId sorting based on senderId and receiverId
    String sortedRoomId =
        (int.parse(senderId) < int.parse(receiverId)) ? 'room_${senderId}_$receiverId' : 'room_${receiverId}_$senderId';

    roomId = sortedRoomId;

    // Generate a unique message ID for each message
    String messageId = uuid.v4(); // This creates a unique ID for each message

    final msg = AdminChatMessageModel(
      senderName: senderName,
      senderId: senderId,
      receiverName: receiverName,
      message: text,
      messageTime: time,
      messageType: AdminChatMessageTypeEnum.text,
      userId: receiverId, // Assuming userId is same as senderId
    );

    await _firestore
        .collection('DashboardChat')
        .doc(roomId.toString())
        .collection('messages')
        .doc(messageId)
        .set(msg.toJson())
        .then((value) {
      _firestore.collection('DashboardChat').doc(roomId.toString()).set({
        'lastMessageTimestamp': DateTime.now(),
        'createdAt': DateTime.now(),
        'roomId': roomId.toString(),
        'users': [receiverId, senderId],
      });
      ApiHelper.instance.sendNotification(
        deviceToken: adminDeviceToken,
        titleName: senderName,
        body: text,
        data: {
          'sender_id': senderId,
          'receiver_id': receiverId,
          'sender_name': senderName,
          'receiver_name': receiverName,
          'msg_type': '4',
          'admin_device_token': adminDeviceToken,
          'click_action': 'https://fasakhaninja.com/admin/chat/?user_id=$senderId',
        },
      );
    });
  }
}

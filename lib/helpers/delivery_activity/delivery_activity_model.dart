class DeliveryActivityModel {
  final String? orderStatus;
  final String? orderId;
  final String? orderNo;
  final String? restaurantName;
  final String? updatedAt;

  const DeliveryActivityModel({this.orderStatus, this.orderId, this.orderNo, this.restaurantName, this.updatedAt});

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (orderStatus != null) {
      map['order_status'] = orderStatus;
      map['orderStatus'] = orderStatus;
    }
    if (orderId != null && orderId!.trim().isNotEmpty) {
      map['order_id'] = orderId;
      map['orderId'] = orderId;
    }
    if (orderNo != null && orderNo!.trim().isNotEmpty) {
      map['order_no'] = orderNo;
      map['orderNo'] = orderNo;
    }
    if (restaurantName != null && restaurantName!.trim().isNotEmpty) {
      map['restaurant_name'] = restaurantName;
      map['restaurantName'] = restaurantName;
    }

    if (updatedAt != null) map['updated_at'] = updatedAt;
    return map;
  }

  DeliveryActivityModel copyWith({String? orderStatus, String? orderId, String? orderNo, String? restaurantName, String? updatedAt}) {
    return DeliveryActivityModel(
      orderStatus: orderStatus ?? this.orderStatus,
      orderId: orderId ?? this.orderId,
      orderNo: orderNo ?? this.orderNo,
      restaurantName: restaurantName ?? this.restaurantName,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

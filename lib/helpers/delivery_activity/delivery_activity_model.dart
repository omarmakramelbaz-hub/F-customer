class DeliveryActivityModel {
  final String? orderStatus;
  final String? orderId;
  final String? restaurantName;
  final int? updatedAt;

  const DeliveryActivityModel(
      {this.orderStatus, this.orderId, this.restaurantName, this.updatedAt});

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

    if (restaurantName != null) map['restaurant_name'] = restaurantName;
    if (updatedAt != null) map['updated_at'] = updatedAt;
    return map;
  }

  DeliveryActivityModel copyWith({String? orderStatus, String? orderId}) {
    return DeliveryActivityModel(
      orderStatus: orderStatus ?? this.orderStatus,
      orderId: orderId ?? this.orderId,
      restaurantName: restaurantName,
      updatedAt: updatedAt,
    );
  }
}

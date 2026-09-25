class AcceptedDelegateModel {
  List<Delegates>? delegates;
  Order? order;

  AcceptedDelegateModel({this.delegates, this.order});

  AcceptedDelegateModel.fromJson(Map<String, dynamic> json) {
    if (json['delegates'] != null) {
      delegates = <Delegates>[];
      json['delegates'].forEach((v) {
        delegates!.add(Delegates.fromJson(v));
      });
    }
    order = json['order'] != null ? Order.fromJson(json['order']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (delegates != null) {
      data['delegates'] = delegates!.map((v) => v.toJson()).toList();
    }
    if (order != null) {
      data['order'] = order!.toJson();
    }
    return data;
  }
}

class Delegates {
  int? id;
  String? name;
  String? accountType;
  String? lat;
  String? lng;
  String? photoProfile;
  int? completedOrdersCount;
  num? offerPrice;
  String? offerStatus;

  Delegates({this.id, this.name, this.accountType, this.lat, this.lng, this.photoProfile, this.completedOrdersCount, this.offerPrice, this.offerStatus});

  Delegates.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    accountType = json['account_type'];
    lat = json['lat'];
    lng = json['lng'];
    photoProfile = json['photo_profile'];
    completedOrdersCount = json['completed_orders_count'];
    offerPrice = json['offer_price'];
    offerStatus = json['offer_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['account_type'] = accountType;
    data['lat'] = lat;
    data['lng'] = lng;
    data['photo_profile'] = photoProfile;
    data['completed_orders_count'] = completedOrdersCount;
    data['offer_price'] = offerPrice;
    data['offer_status'] = offerStatus;
    return data;
  }
}

class Order {
  int? id;
  String? orderNo;
  int? delegateId;
  String? delegateName;
  String? delegateMobile;
  String? delegateLogo;
  int? userId;
  String? userName;
  num? userBalance;
  String? userMobile;
  String? userLocation;
  String? userLogo;
  String? status;
  String? type;
  String? orderType;
  String? paymentType;
  String? createdAt;
  String? updatedAt;
  String? description;
  String? fromLat;
  String? fromLng;
  String? toLat;
  String? toLng;
  String? fromAddress;
  String? toAddress;
  num? actualPrice;
  num? expectedPrice;
  int? admin;
  String? settingMobile;

  Order({
    this.id,
    this.orderNo,
    this.delegateId,
    this.delegateName,
    this.delegateMobile,
    this.delegateLogo,
    this.userId,
    this.userName,
    this.userBalance,
    this.userMobile,
    this.userLocation,
    this.userLogo,
    this.status,
    this.type,
    this.orderType,
    this.paymentType,
    this.createdAt,
    this.updatedAt,
    this.description,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    this.fromAddress,
    this.toAddress,
    this.actualPrice,
    this.expectedPrice,
    this.admin,
    this.settingMobile,
  });

  Order.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    orderNo = json['order_no'];
    delegateId = json['delegate_id'];
    delegateName = json['delegate_name'];
    delegateMobile = json['delegate_mobile'];
    delegateLogo = json['delegate_logo'];
    userId = json['user_id'];
    userName = json['user_name'];
    userBalance = json['user_balance'];
    userMobile = json['user_mobile'];
    userLocation = json['user_location'];
    userLogo = json['user_logo'];
    status = json['status'];
    type = json['type'];
    orderType = json['order_type'];
    paymentType = json['payment_type'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    description = json['description'];
    fromLat = json['from_lat'];
    fromLng = json['from_lng'];
    toLat = json['to_lat'];
    toLng = json['to_lng'];
    fromAddress = json['from_address'];
    toAddress = json['to_address'];
    actualPrice = json['actual_price'];
    expectedPrice = json['expected_price'];
    admin = json['admin'];
    settingMobile = json['setting_mobile'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['order_no'] = orderNo;
    data['delegate_id'] = delegateId;
    data['delegate_name'] = delegateName;
    data['delegate_mobile'] = delegateMobile;
    data['delegate_logo'] = delegateLogo;
    data['user_id'] = userId;
    data['user_name'] = userName;
    data['user_balance'] = userBalance;
    data['user_mobile'] = userMobile;
    data['user_location'] = userLocation;
    data['user_logo'] = userLogo;
    data['status'] = status;
    data['type'] = type;
    data['order_type'] = orderType;
    data['payment_type'] = paymentType;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['description'] = description;
    data['from_lat'] = fromLat;
    data['from_lng'] = fromLng;
    data['to_lat'] = toLat;
    data['to_lng'] = toLng;
    data['from_address'] = fromAddress;
    data['to_address'] = toAddress;
    data['actual_price'] = actualPrice;
    data['expected_price'] = expectedPrice;
    data['admin'] = admin;
    data['setting_mobile'] = settingMobile;
    return data;
  }
}

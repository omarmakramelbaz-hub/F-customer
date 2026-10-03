class FavoriteModel {
  int? id;
  int? vendorId;
  String? vendorName;
  String? name;
  String? status;
  num? avgRate;
  String? address;
  String? logo;
  String? bgImage;
  String? deliveryTime;
  String? openAt;
  String? closeAt;
  String? lat;
  String? lng;
  String? createdAt;
  num? productPrice;
  int? resturantId;
  String? resturantName;
  int? productId;

  FavoriteModel({
    this.id,
    this.vendorId,
    this.vendorName,
    this.name,
    this.status,
    this.avgRate,
    this.address,
    this.logo,
    this.bgImage,
    this.deliveryTime,
    this.openAt,
    this.closeAt,
    this.lat,
    this.lng,
    this.createdAt,
    this.productPrice,
    this.resturantId,
    this.resturantName,
    this.productId,
  });

  FavoriteModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    vendorId = json['vendor_id'];
    vendorName = json['vendor_name'];
    name = json['name'] ?? json['product_name'] ?? json['product_title'];
    status = json['status'];
    avgRate = json['avg_rate'] ?? 0;
    address = json['address'] ?? json['resturant_name'] ?? '';
    logo = json['logo'] ?? json['product_image'] ?? '';
    bgImage = json['bg_image'] ?? json['product_image'] ?? '';
    deliveryTime = json['delivery_time'] ?? '';
    openAt = json['open_at'];
    closeAt = json['close_at'];
    lat = json['lat'];
    lng = json['lng'];
    createdAt = json['created_at'];
    productPrice = json['product_price'];
    resturantId = json['resturant_id'];
    resturantName = json['resturant_name'];
    productId = json['product_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['vendor_id'] = vendorId;
    data['vendor_name'] = vendorName;
    data['name'] = name;
    data['status'] = status;
    data['avg_rate'] = avgRate;
    data['address'] = address;
    data['logo'] = logo;
    data['bg_image'] = bgImage;
    data['delivery_time'] = deliveryTime;
    data['open_at'] = openAt;
    data['close_at'] = closeAt;
    data['lat'] = lat;
    data['lng'] = lng;
    data['created_at'] = createdAt;
    data['product_price'] = productPrice;
    data['resturant_id'] = resturantId;
    data['resturant_name'] = resturantName;
    data['product_id'] = productId;
    return data;
  }
}

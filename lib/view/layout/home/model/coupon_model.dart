import 'draw_badge.dart';

class CouponModel {
  String? flag;
  Data? data;
  String? winner;
  WinnerData? winnerData;
  /// Every draw running now (by order total and by chosen products).
  List<Data> draws = [];
  /// The draws ended in the last 30 days and their winning codes.
  List<DrawWinner> recentWinners = [];

  CouponModel({this.flag, this.data, this.winner, this.winnerData});

  CouponModel.fromJson(Map<String, dynamic> json) {
    flag = json['flag'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    winner = json['winner'];
    winnerData = json['winner_data'] != null ? WinnerData.fromJson(json['winner_data']) : null;
    if (json['draws'] is List) {
      draws = (json['draws'] as List).whereType<Map>().map((v) => Data.fromJson(Map<String, dynamic>.from(v))).toList();
    }
    if (json['recent_winners'] is List) {
      recentWinners = (json['recent_winners'] as List).map(DrawWinner.fromJson).whereType<DrawWinner>().toList();
    }
  }

  /// The running draws by chosen products (their items carry the badge in every branch).
  List<Data> get productDraws => draws.where((d) => d.isByProducts).toList();

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['flag'] = flag;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['winner'] = winner;
    if (winnerData != null) {
      data['winner_data'] = winnerData!.toJson();
    }
    return data;
  }
}

class Data {
  int? id;
  String? name;
  String? price;
  String? drawAmount;
  String? startDate;
  String? endDate;
  String? status;
  String? image;
  List<Resturants>? resturants;
  String? createdAt;
  int? eligibleOrdersCount;
  num? eligibleOrdersTotal;
  /// «order_total» (an order of at least [price]) or «product» (each piece of [products] bought from any branch).
  String policy = 'order_total';
  List<DrawProduct> products = [];
  String? badgeLabel;
  /// The customer's entry codes in this draw, and the winning code once drawn.
  List<String> myCodes = [];
  String? winnerCode;

  bool get isByProducts => policy == 'product';

  Data({
    this.id,
    this.name,
    this.price,
    this.drawAmount,
    this.startDate,
    this.endDate,
    this.status,
    this.image,
    this.resturants,
    this.createdAt,
    this.eligibleOrdersCount,
    this.eligibleOrdersTotal,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    price = json['price']?.toString();
    drawAmount = (json['draw_amount'] ??
            json['raffle_amount'] ??
            json['prize_amount'] ??
            json['prize'] ??
            json['reward'] ??
            json['amount'])
        ?.toString();
    startDate = json['start_date'];
    endDate = json['end_date'];
    status = json['status'];
    image = json['image'];
    if (json['resturants'] != null) {
      resturants = <Resturants>[];
      json['resturants'].forEach((v) {
        resturants!.add(Resturants.fromJson(v));
      });
    }
    createdAt = json['created_at'];
    eligibleOrdersCount = int.tryParse(json['eligible_orders_count']?.toString() ?? '') ?? 0;
    eligibleOrdersTotal = num.tryParse(json['eligible_orders_total']?.toString() ?? '') ?? 0;
    policy = json['policy']?.toString() ?? 'order_total';
    if (json['products'] is List) {
      products = (json['products'] as List).whereType<Map>().map((v) => DrawProduct.fromJson(v)).toList();
    }
    badgeLabel = json['badge_label']?.toString();
    if (json['my_codes'] is List) myCodes = (json['my_codes'] as List).map((v) => v.toString()).toList();
    final winner = json['winner_code']?.toString() ?? '';
    winnerCode = winner.isEmpty ? null : winner;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['price'] = price;
    if (drawAmount != null) data['draw_amount'] = drawAmount;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['status'] = status;
    data['image'] = image;
    if (resturants != null) {
      data['resturants'] = resturants!.map((v) => v.toJson()).toList();
    }
    data['created_at'] = createdAt;
    data['eligible_orders_count'] = eligibleOrdersCount;
    data['eligible_orders_total'] = eligibleOrdersTotal;
    return data;
  }
}

class Resturants {
  int? id;
  int? vendorId;
  String? vendorName;
  String? vendorEmail;
  String? name;
  String? status;
  double? avgRate;
  String? address;
  String? logo;
  String? bgImage;
  String? deliveryTime;
  String? resturantPhone;
  String? lat;
  String? lng;
  String? countryName;
  String? cityName;
  String? createdAt;
  int? cityId;
  String? cityname;
  String? underContract;
  int? serviceFees;
  String? closeAt;
  String? openAt;
  int? minOrderPrice;
  int? kmPrice;

  Resturants({
    this.id,
    this.vendorId,
    this.vendorName,
    this.vendorEmail,
    this.name,
    this.status,
    this.avgRate,
    this.address,
    this.logo,
    this.bgImage,
    this.deliveryTime,
    this.resturantPhone,
    this.lat,
    this.lng,
    this.countryName,
    this.cityName,
    this.createdAt,
    this.cityId,
    this.cityname,
    this.underContract,
    this.serviceFees,
    this.closeAt,
    this.openAt,
    this.minOrderPrice,
    this.kmPrice,
  });

  Resturants.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    vendorId = json['vendor_id'];
    vendorName = json['vendor_name'];
    vendorEmail = json['vendor_email'];
    name = json['name'];
    status = json['status'];
    avgRate = double.tryParse(json['avg_rate'].toString()) ?? 0.0;
    address = json['address'];
    logo = json['logo'];
    bgImage = json['bg_image'];
    deliveryTime = json['delivery_time'];
    resturantPhone = json['resturant_phone'];
    lat = json['lat'];
    lng = json['lng'];
    countryName = json['country_name'];
    cityName = json['city_name'];
    createdAt = json['created_at'];
    cityId = json['city_id'];
    cityname = json['cityname'];
    underContract = json['under_contract'];
    serviceFees = json['service_fees'];
    closeAt = json['close_at'];
    openAt = json['open_at'];
    minOrderPrice = json['min_order_price'];
    kmPrice = json['km_price'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['vendor_id'] = vendorId;
    data['vendor_name'] = vendorName;
    data['vendor_email'] = vendorEmail;
    data['name'] = name;
    data['status'] = status;
    data['avg_rate'] = avgRate;
    data['address'] = address;
    data['logo'] = logo;
    data['bg_image'] = bgImage;
    data['delivery_time'] = deliveryTime;
    data['resturant_phone'] = resturantPhone;
    data['lat'] = lat;
    data['lng'] = lng;
    data['country_name'] = countryName;
    data['city_name'] = cityName;
    data['created_at'] = createdAt;
    data['city_id'] = cityId;
    data['cityname'] = cityname;
    data['under_contract'] = underContract;
    data['service_fees'] = serviceFees;
    data['close_at'] = closeAt;
    data['open_at'] = openAt;
    data['min_order_price'] = minOrderPrice;
    data['km_price'] = kmPrice;
    return data;
  }
}

class WinnerData {
  int? id;
  String? name;
  String? accountType;
  String? lat;
  String? lng;
  String? photoProfile;
  int? completedOrdersCount;

  WinnerData({this.id, this.name, this.accountType, this.lat, this.lng, this.photoProfile, this.completedOrdersCount});

  WinnerData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    accountType = json['account_type'];
    lat = json['lat'];
    lng = json['lng'];
    photoProfile = json['photo_profile'];
    completedOrdersCount = json['completed_orders_count'];
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
    return data;
  }
}

/// A product whose purchase enters a draw by products.
class DrawProduct {
  final int? id;
  final String name;
  const DrawProduct({this.id, required this.name});
  factory DrawProduct.fromJson(Map json) => DrawProduct(id: int.tryParse(json['id']?.toString() ?? ''), name: json['name']?.toString() ?? '');
}

class UserCartModel {
  Resturant? resturant;
  num? totalCart;
  num? userTax;
  List<Carts>? carts;
  List<RecommendedProducts>? recommendedProducts;

  UserCartModel({this.resturant, this.totalCart, this.userTax, this.carts, this.recommendedProducts});

  UserCartModel.fromJson(Map<String, dynamic> json) {
    resturant = json['resturant'] != null ? Resturant.fromJson(json['resturant']) : null;
    totalCart = json['total_cart'];
    userTax = json['user_tax'];
    if (json['carts'] != null) {
      carts = <Carts>[];
      json['carts'].forEach((v) {
        carts!.add(Carts.fromJson(v));
      });
    }
    if (json['recommendedProducts'] != null) {
      recommendedProducts = <RecommendedProducts>[];
      json['recommendedProducts'].forEach((v) {
        recommendedProducts!.add(RecommendedProducts.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (resturant != null) {
      data['resturant'] = resturant!.toJson();
    }
    data['total_cart'] = totalCart;
    data['user_tax'] = userTax;
    if (carts != null) {
      data['carts'] = carts!.map((v) => v.toJson()).toList();
    }
    if (recommendedProducts != null) {
      data['recommendedProducts'] = recommendedProducts!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Resturant {
  int? id;
  int? resturantId;
  String? resturantName;
  String? resturantStatus;
  String? resturantOpenAt;
  String? resturantCloseAt;
  String? resturantLogo;
  bool? resturantZone;
  String? zoneDay;
  String? zoneType;
  List<ResturantAreas>? resturantAreas;
  num? resturantMinOrderPrice;
  num? resturantKmPrice;
  num? resturantServiceFees;
  num? tax;
  num? serviceFees;
  num? default_0_1;
  num? default_1_2;
  num? default_2_3;
  Resturant({
    this.id,
    this.resturantId,
    this.resturantName,
    this.resturantStatus,
    this.resturantOpenAt,
    this.resturantCloseAt,
    this.resturantLogo,
    this.resturantZone,
    this.zoneDay,
    this.zoneType,
    this.resturantAreas,
    this.resturantMinOrderPrice,
    this.resturantKmPrice,
    this.resturantServiceFees,
    this.tax,
    this.serviceFees,
    this.default_0_1,
    this.default_1_2,
    this.default_2_3,
  });

  Resturant.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    resturantId = json['resturant_id'];
    resturantName = json['resturant_name'];
    resturantStatus = json['resturant_status'];
    resturantOpenAt = json['resturant_open_at'];
    resturantCloseAt = json['resturant_close_at'];
    resturantLogo = json['resturant_logo'];
    resturantZone = json['resturant_zone'];
    zoneDay = json['zone_day'];
    zoneType = json['zone_type'];
    if (json['resturant_areas'] != null) {
      resturantAreas = <ResturantAreas>[];
      json['resturant_areas'].forEach((v) {
        resturantAreas!.add(ResturantAreas.fromJson(v));
      });
    }
    resturantMinOrderPrice = json['resturant_min_order_price'];
    resturantKmPrice = json['resturant_km_price'];
    resturantServiceFees = json['resturant_service_fees'];
    tax = json['tax'];
    serviceFees = json['service_fees'];
    default_0_1 = json['default_0_1'];
    default_1_2 = json['default_1_2'];
    default_2_3 = json['default_2_3'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['resturant_id'] = resturantId;
    data['resturant_name'] = resturantName;
    data['resturant_status'] = resturantStatus;
    data['resturant_open_at'] = resturantOpenAt;
    data['resturant_close_at'] = resturantCloseAt;
    data['resturant_logo'] = resturantLogo;
    data['resturant_zone'] = resturantZone;
    data['zone_day'] = zoneDay;
    data['zone_type'] = zoneType;
    if (resturantAreas != null) {
      data['resturant_areas'] = resturantAreas!.map((v) => v.toJson()).toList();
    }
    data['resturant_min_order_price'] = resturantMinOrderPrice;
    data['resturant_km_price'] = resturantKmPrice;
    data['resturant_service_fees'] = resturantServiceFees;
    data['tax'] = tax;
    data['service_fees'] = serviceFees;
    data['default_0_1'] = default_0_1;
    data['default_1_2'] = default_1_2;
    data['default_2_3'] = default_2_3;
    return data;
  }
}

class ResturantAreas {
  int? id;
  int? addedBy;
  int? resturantId;
  String? expectedDelivery;
  String? createdAt;
  String? updatedAt;
  int? areaId;
  String? type;

  ResturantAreas({
    this.id,
    this.addedBy,
    this.resturantId,
    this.expectedDelivery,
    this.createdAt,
    this.updatedAt,
    this.areaId,
    this.type,
  });

  ResturantAreas.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    addedBy = json['added_by'];
    resturantId = json['resturant_id'];
    expectedDelivery = json['expected_delivery'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    areaId = json['area_id'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['added_by'] = addedBy;
    data['resturant_id'] = resturantId;
    data['expected_delivery'] = expectedDelivery;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['area_id'] = areaId;
    data['type'] = type;
    return data;
  }
}

class Carts {
  int? id;
  ResturantProduct? resturantProduct;
  int? resturantId;
  String? resturantName;
  String? resturantLat;
  String? resturantLng;
  String? resturantCityName;
  String? resturantStatus;
  String? resturantDeliveryTime;
  int? orderId;
  num? price;
  int? qty;
  int? productFeature;
  String? productFeatureName;
  String? productClean;
  String? createdAt;
  num? minOrderPrice;
  num? total;
  num? updatedTotal;
  String? reasonUpdateTotal;

  Carts({
    this.id,
    this.resturantProduct,
    this.resturantId,
    this.resturantName,
    this.resturantLat,
    this.resturantLng,
    this.resturantCityName,
    this.resturantStatus,
    this.resturantDeliveryTime,
    this.orderId,
    this.price,
    this.qty,
    this.productFeature,
    this.productFeatureName,
    this.productClean,
    this.createdAt,
    this.minOrderPrice,
    this.total,
    this.updatedTotal,
    this.reasonUpdateTotal,
  });

  Carts.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    resturantProduct = json['resturant_product'] != null ? ResturantProduct.fromJson(json['resturant_product']) : null;
    resturantId = json['resturant_id'];
    resturantName = json['resturant_name'];
    resturantStatus = json['resturant_status'];
    resturantLat = json['resturant_lat'];
    resturantLng = json['resturant_lng'];
    resturantCityName = json['resturant_city_name'];
    resturantDeliveryTime = json['resturant_delivery_time'];
    orderId = json['order_id'];
    price = json['price'];
    qty = json['qty'];
    productFeature = json['product_feature'];
    productFeatureName = json['product_feature_name'];
    productClean = json['product_clean'];
    createdAt = json['created_at'];
    minOrderPrice = json['min_order_price'];
    total = json['total'];
    updatedTotal = json['updated_total'];
    reasonUpdateTotal = json['reason_update_total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (resturantProduct != null) {
      data['resturant_product'] = resturantProduct!.toJson();
    }
    data['resturant_id'] = resturantId;
    data['resturant_name'] = resturantName;
    data['resturant_lat'] = resturantLat;
    data['resturant_lng'] = resturantLng;
    data['resturant_city_name'] = resturantCityName;
    data['resturant_status'] = resturantStatus;
    data['resturant_delivery_time'] = resturantDeliveryTime;
    data['order_id'] = orderId;
    data['price'] = price;
    data['qty'] = qty;
    data['product_feature'] = productFeature;
    data['product_feature_name'] = productFeatureName;
    data['product_clean'] = productClean;
    data['created_at'] = createdAt;
    data['min_order_price'] = minOrderPrice;
    data['total'] = total;
    data['updated_total'] = updatedTotal;
    data['reason_update_total'] = reasonUpdateTotal;
    return data;
  }
}

class ResturantProduct {
  int? id;
  int? vendorId;
  String? vendorName;
  int? resturantId;
  String? resturantName;
  String? productName;
  String? productDescription;
  List<Features>? features;
  num? productPrice;
  num? extraCombo;
  num? extraLarge;
  num? extraMedium;
  num? extraClean;
  num? extraClear;
  num? extraVacuim;
  num? categoryId;
  String? categoryName;
  int? subCategoryId;
  String? subCategoryName;
  int? productId;
  String? productTitle;
  String? status;
  int? hasClean;
  String? productImage;
  String? createdAt;

  ResturantProduct({
    this.id,
    this.vendorId,
    this.vendorName,
    this.resturantId,
    this.resturantName,
    this.productName,
    this.productDescription,
    this.features,
    this.productPrice,
    this.extraCombo,
    this.extraLarge,
    this.extraMedium,
    this.extraClean,
    this.extraClear,
    this.extraVacuim,
    this.categoryId,
    this.categoryName,
    this.subCategoryId,
    this.subCategoryName,
    this.productId,
    this.productTitle,
    this.status,
    this.hasClean,
    this.productImage,
    this.createdAt,
  });

  ResturantProduct.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    vendorId = json['vendor_id'];
    vendorName = json['vendor_name'];
    resturantId = json['resturant_id'];
    resturantName = json['resturant_name'];
    productName = json['product_name'];
    productDescription = json['product_description'];
    if (json['features'] != null) {
      features = <Features>[];
      json['features'].forEach((v) {
        features!.add(Features.fromJson(v));
      });
    }
    productPrice = json['product_price'];
    extraCombo = json['extra_combo'];
    extraLarge = json['extra_large'];
    extraMedium = json['extra_medium'];
    extraClean = json['extra_clean'];
    extraClear = json['extra_clear'];
    extraVacuim = json['extra_vacuim'];
    categoryId = json['category_id'];
    categoryName = json['category_name'];
    subCategoryId = json['sub_category_id'];
    subCategoryName = json['sub_category_name'];
    productId = json['product_id'];
    productTitle = json['product_title'];
    status = json['status'];
    hasClean = json['has_clean'];
    productImage = json['product_image'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['vendor_id'] = vendorId;
    data['vendor_name'] = vendorName;
    data['resturant_id'] = resturantId;
    data['resturant_name'] = resturantName;
    data['product_name'] = productName;
    data['product_description'] = productDescription;
    if (features != null) {
      data['features'] = features!.map((v) => v.toJson()).toList();
    }
    data['product_price'] = productPrice;
    data['extra_combo'] = extraCombo;
    data['extra_large'] = extraLarge;
    data['extra_medium'] = extraMedium;
    data['extra_clean'] = extraClean;
    data['extra_clear'] = extraClear;
    data['extra_vacuim'] = extraVacuim;
    data['category_id'] = categoryId;
    data['category_name'] = categoryName;
    data['sub_category_id'] = subCategoryId;
    data['sub_category_name'] = subCategoryName;
    data['product_id'] = productId;
    data['product_title'] = productTitle;
    data['status'] = status;
    data['has_clean'] = hasClean;
    data['product_image'] = productImage;
    data['created_at'] = createdAt;
    return data;
  }
}

class RecommendedProducts {
  int? id;
  int? vendorId;
  String? vendorName;
  int? resturantId;
  String? resturantName;
  String? productName;
  String? productDescription;
  List<Features>? features;
  num? productPrice;
  num? extraCombo;
  num? extraLarge;
  num? extraMedium;
  num? extraClean;
  num? extraClear;
  num? extraVacuim;
  int? categoryId;
  String? categoryName;
  int? subCategoryId;
  String? subCategoryName;
  int? productId;
  String? productTitle;
  String? status;
  String? highestRated;
  int? hasClean;
  String? productImage;
  String? createdAt;
  int? latestOrderId;
  int? latestOrderQty;
  String? latestOrderProductClean;
  int? latestOrderProductFeature;

  RecommendedProducts({
    this.id,
    this.vendorId,
    this.vendorName,
    this.resturantId,
    this.resturantName,
    this.productName,
    this.productDescription,
    this.features,
    this.productPrice,
    this.extraCombo,
    this.extraLarge,
    this.extraMedium,
    this.extraClean,
    this.extraClear,
    this.extraVacuim,
    this.categoryId,
    this.categoryName,
    this.subCategoryId,
    this.subCategoryName,
    this.productId,
    this.productTitle,
    this.status,
    this.highestRated,
    this.hasClean,
    this.productImage,
    this.createdAt,
    this.latestOrderId,
    this.latestOrderQty,
    this.latestOrderProductClean,
    this.latestOrderProductFeature,
  });

  RecommendedProducts.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    vendorId = json['vendor_id'];
    vendorName = json['vendor_name'];
    resturantId = json['resturant_id'];
    resturantName = json['resturant_name'];
    productName = json['product_name'];
    productDescription = json['product_description'];
    if (json['features'] != null) {
      features = <Features>[];
      json['features'].forEach((v) {
        features!.add(Features.fromJson(v));
      });
    }
    productPrice = json['product_price'];
    extraCombo = json['extra_combo'];
    extraLarge = json['extra_large'];
    extraMedium = json['extra_medium'];
    extraClean = json['extra_clean'];
    extraClear = json['extra_clear'];
    extraVacuim = json['extra_vacuim'];
    categoryId = json['category_id'];
    categoryName = json['category_name'];
    subCategoryId = json['sub_category_id'];
    subCategoryName = json['sub_category_name'];
    productId = json['product_id'];
    productTitle = json['product_title'];
    status = json['status'];
    highestRated = json['highest_rated'];
    hasClean = json['has_clean'];
    productImage = json['product_image'];
    createdAt = json['created_at'];
    latestOrderId = json['latest_order_id'];
    latestOrderQty = json['latest_order_qty'];
    latestOrderProductClean = json['latest_order_product_clean'];
    latestOrderProductFeature = json['latest_order_product_feature'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['vendor_id'] = vendorId;
    data['vendor_name'] = vendorName;
    data['resturant_id'] = resturantId;
    data['resturant_name'] = resturantName;
    data['product_name'] = productName;
    data['product_description'] = productDescription;
    if (features != null) {
      data['features'] = features!.map((v) => v.toJson()).toList();
    }
    data['product_price'] = productPrice;
    data['extra_combo'] = extraCombo;
    data['extra_large'] = extraLarge;
    data['extra_medium'] = extraMedium;
    data['extra_clean'] = extraClean;
    data['extra_clear'] = extraClear;
    data['extra_vacuim'] = extraVacuim;
    data['category_id'] = categoryId;
    data['category_name'] = categoryName;
    data['sub_category_id'] = subCategoryId;
    data['sub_category_name'] = subCategoryName;
    data['product_id'] = productId;
    data['product_title'] = productTitle;
    data['status'] = status;
    data['highest_rated'] = highestRated;
    data['has_clean'] = hasClean;
    data['product_image'] = productImage;
    data['created_at'] = createdAt;
    data['latest_order_id'] = latestOrderId;
    data['latest_order_qty'] = latestOrderQty;
    data['latest_order_product_clean'] = latestOrderProductClean;
    data['latest_order_product_feature'] = latestOrderProductFeature;
    return data;
  }
}

class Features {
  int? id;
  String? name;
  String? createdAt;

  Features({this.id, this.name, this.createdAt});

  Features.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['created_at'] = createdAt;
    return data;
  }
}

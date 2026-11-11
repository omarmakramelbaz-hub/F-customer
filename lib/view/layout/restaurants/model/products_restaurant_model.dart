import '../../home/model/draw_badge.dart';

class ProductsRestaurantModel {
  int? categoryId;
  String? categoryName;
  int? subcategoryId;
  String? subcategoryName;
  List<ResturantItems>? resturantItems;

  ProductsRestaurantModel({
    this.categoryId,
    this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
    this.resturantItems,
  });

  ProductsRestaurantModel.fromJson(Map<String, dynamic> json) {
    categoryId = json['category_id'];
    categoryName = json['category_name'];
    subcategoryId = json['subcategory_id'];
    subcategoryName = json['subcategory_name'];
    if (json['resturant_items'] != null) {
      resturantItems = <ResturantItems>[];
      json['resturant_items'].forEach((v) {
        resturantItems!.add(ResturantItems.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['category_id'] = categoryId;
    data['category_name'] = categoryName;
    data['subcategory_id'] = subcategoryId;
    data['subcategory_name'] = subcategoryName;
    if (resturantItems != null) {
      data['resturant_items'] = resturantItems!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ResturantItems {
  int? id;
  int? vendorId;
  String? vendorName;
  int? resturantId;
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
  /// The draw this item qualifies for (its card shows [DrawBadge.label]), or null.
  DrawBadge? draw;

  ResturantItems({
    this.id,
    this.vendorId,
    this.vendorName,
    this.resturantId,
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

  ResturantItems.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    vendorId = json['vendor_id'];
    vendorName = json['vendor_name'];
    resturantId = json['resturant_id'];
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
    draw = DrawBadge.fromJson(json['draw']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['vendor_id'] = vendorId;
    data['vendor_name'] = vendorName;
    data['resturant_id'] = resturantId;
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
    if (draw != null) data['draw'] = draw!.toJson();
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

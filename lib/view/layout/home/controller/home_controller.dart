import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/utils.dart';
import '../../restaurants/screen/restaurant_details_screen.dart';
import '../model/coupon_model.dart';
import '../model/previous_order_home_model.dart';
import '../model/restaurants_near_you_home_model.dart';
import '../model/slider_model.dart';

class HomeController extends ChangeNotifier {
  Future<ApiResponse> _get(String url, {Map<String, dynamic>? query}) =>
      ApiHelper.instance.get(url, queryParameters: query);

  Future<void> _fetchAndMapList<T>({
    required Future<ApiResponse> Function() apiCall,
    required T Function(dynamic) mapper,
    required void Function(ApiResponse) setResponse,
    required void Function(List<T>) setList,
  }) async {
    setResponse(ApiResponse(state: ResponseState.loading, data: null));
    setList([]);
    notifyListeners();

    final response = await apiCall();
    setResponse(response);
    notifyListeners();

    if (response.state == ResponseState.complete) {
      final data = response.data['data'];
      if (data != null && data is Iterable) {
        setList(data.map(mapper).toList());
      } else {
        setList([]);
      }
      notifyListeners();
    }
  }

  Future<void> _fetchSingle<T>({
    required Future<ApiResponse> Function() apiCall,
    required T Function(dynamic) mapper,
    required void Function(ApiResponse) setResponse,
    required void Function(T?) setValue,
  }) async {
    setResponse(ApiResponse(state: ResponseState.loading, data: null));
    setValue(null);
    notifyListeners();

    final response = await apiCall();
    setResponse(response);
    if (response.state == ResponseState.complete) {
      setValue(mapper(response.data['data']));
    } else {
      setValue(null);
    }
    notifyListeners();
  }

  ApiResponse _headerImageResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get headerImageResponse => _headerImageResponse;
  String? _headerImageUrl;
  String? get headerImageUrl => _headerImageUrl;

  void initialHeaderImage() {
    _headerImageResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _headerImageUrl = null;
    notifyListeners();
  }

  Future<void> getHeaderImage() async {
    _headerImageResponse = ApiResponse(state: ResponseState.loading, data: null);
    notifyListeners();

    final response = await _get(Urls.setting);
    _headerImageResponse = response;

    if (response.state == ResponseState.complete) {
      final data = response.data['data'];
      final value = data is Map ? data['header_image'] : null;
      _headerImageUrl = value?.toString().trim().isNotEmpty == true ? value.toString().trim() : null;
    } else {
      _headerImageUrl = null;
    }

    notifyListeners();
  }

  ApiResponse _sliderResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get sliderResponse => _sliderResponse;
  List<SliderModel> _slider = [];
  List<SliderModel> get slider => _slider;

  void initialSlider() {
    _sliderResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _slider = [];
    notifyListeners();
  }

  Future<void> getSlider() async {
    await _fetchAndMapList<SliderModel>(
      apiCall: () => _get(
        Urls.slider,
        query: {
          if (HiveMethods.getLat() != null && HiveMethods.getLan() != null) ...{
            'lat': HiveMethods.getLat(),
            'lng': HiveMethods.getLan(),
          },
        },
      ),
      mapper: (e) => SliderModel.fromJson(e),
      setResponse: (r) => _sliderResponse = r,
      setList: (l) => _slider = l,
    );
  }

  ApiResponse _defaultSliderResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get defaultSliderResponse => _defaultSliderResponse;
  List<SliderModel> _defaultSlider = [];
  List<SliderModel> get defaultSlider => _defaultSlider;

  void initialDefaultSlider() {
    _defaultSliderResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _defaultSlider = [];
    notifyListeners();
  }

  Future<void> getDefaultSlider() async {
    await _fetchAndMapList<SliderModel>(
      apiCall: () => _get(Urls.slider),
      mapper: (e) => SliderModel.fromJson(e),
      setResponse: (r) => _defaultSliderResponse = r,
      setList: (l) => _defaultSlider = l,
    );
  }

  ApiResponse _previousOrderApiResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get previousOrderApiResponse => _previousOrderApiResponse;
  List<PreviousOrderHomeModel> _previousOrders = [];
  List<PreviousOrderHomeModel> get previousOrders => _previousOrders;

  void initialPreviousOrder() {
    _previousOrderApiResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _previousOrders = [];
    notifyListeners();
  }

  void updatePreviousResturant(PreviousOrderHomeModel updatedResturant) {
    final index = _previousOrders.indexWhere((order) => order.id == updatedResturant.id);
    if (index != -1) {
      _previousOrders[index] = updatedResturant;
    } else {
      _previousOrders.add(updatedResturant);
    }
    notifyListeners();
  }

  Future<void> getPreviousOrder() async {
    await _fetchAndMapList<PreviousOrderHomeModel>(
      apiCall: () => _get(Urls.previousOrderHome),
      mapper: (e) => PreviousOrderHomeModel.fromJson(e),
      setResponse: (r) => _previousOrderApiResponse = r,
      setList: (l) => _previousOrders = l,
    );
  }

  ApiResponse _restaurantsNearYouApiResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get restaurantsNearYouApiResponse => _restaurantsNearYouApiResponse;
  List<RestaurantsNearYouHomeModel> _restaurantsNearYou = [];
  List<RestaurantsNearYouHomeModel> get restaurantsNearYou => _restaurantsNearYou;

  void initialRestaurantsNearYou() {
    _restaurantsNearYouApiResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _restaurantsNearYou = [];
    notifyListeners();
  }

  void updateResturantNearestYou(RestaurantsNearYouHomeModel updatedResturant) {
    final index = _restaurantsNearYou.indexWhere((order) => order.id == updatedResturant.id);
    if (index != -1) {
      _restaurantsNearYou[index] = updatedResturant;
    } else {
      _restaurantsNearYou.add(updatedResturant);
    }
    notifyListeners();
  }

  Future<void> getRestaurantsNearYou({double? lat, double? lng}) async {
    _restaurantsNearYouApiResponse = ApiResponse(
      state: ResponseState.loading,
      data: null,
    );
    _restaurantsNearYou = [];
    notifyListeners();

    var response = await _get(
      Urls.restaurants,
      query: {
        if (lat != null && lng != null) ...{'lat': lat, 'lng': lng}
      },
    );

    List<RestaurantsNearYouHomeModel> mapRows(ApiResponse value) {
      if (value.state != ResponseState.complete) {
        return <RestaurantsNearYouHomeModel>[];
      }
      final data = value.data['data'];
      if (data is! Iterable) {
        return <RestaurantsNearYouHomeModel>[];
      }
      return data
          .map((e) => RestaurantsNearYouHomeModel.fromJson(e))
          .toList();
    }

    var rows = mapRows(response);

    // The location-filtered endpoint can legitimately return no rows when an
    // existing branch has not had its delivery-area polygon/radius configured
    // yet. Do not make Fasakhansta disappear from the customer home screen:
    // fall back to the normal branch list while the backend still marks closed
    // or unavailable branches appropriately.
    if (rows.isEmpty && lat != null && lng != null) {
      final fallback = await _get(Urls.restaurants);
      final fallbackRows = mapRows(fallback);
      if (fallback.state == ResponseState.complete && fallbackRows.isNotEmpty) {
        response = fallback;
        rows = fallbackRows;
      }
    }

    _restaurantsNearYouApiResponse = response;
    _restaurantsNearYou = rows;
    notifyListeners();
  }

  ApiResponse _spacialRestaurantsApiResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get spacialRestaurantApiResponse => _spacialRestaurantsApiResponse;
  List<RestaurantsNearYouHomeModel> _spacialRestaurants = [];
  List<RestaurantsNearYouHomeModel> get spacialRestaurants => _spacialRestaurants;

  void initialSpacialRestaurants() {
    _spacialRestaurantsApiResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _spacialRestaurants = [];
    notifyListeners();
  }

  void updateSpacialResturant(RestaurantsNearYouHomeModel updatedResturant) {
    final index = _spacialRestaurants.indexWhere((order) => order.id == updatedResturant.id);
    if (index != -1) {
      _spacialRestaurants[index] = updatedResturant;
    } else {
      _spacialRestaurants.add(updatedResturant);
    }
    notifyListeners();
  }

  Future<void> getSpacialRestaurants({double? lat, double? lng}) async {
    await _fetchAndMapList<RestaurantsNearYouHomeModel>(
      apiCall: () => _get(
        Urls.restaurants,
        query: {
          if (lat != null && lng != null) ...{'lat': lat, 'lng': lng},
          'is_featured': 'yes',
        },
      ),
      mapper: (e) => RestaurantsNearYouHomeModel.fromJson(e),
      setResponse: (r) => _spacialRestaurantsApiResponse = r,
      setList: (l) => _spacialRestaurants = l,
    );
  }

  ApiResponse _countCartResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get countCartResponse => _countCartResponse;
  int _countCart = 0;
  int get countCart => _countCart;

  void initialCountCart() {
    _countCartResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _countCart = 0;
    notifyListeners();
  }

  Future<void> getCountCart() async {
    _countCartResponse = ApiResponse(state: ResponseState.loading, data: null);
    _countCart = 0;
    notifyListeners();

    final response = await _get(Urls.countCart);
    _countCartResponse = response;
    notifyListeners();

    if (response.state == ResponseState.complete) {
      _countCart = response.data['data'] ?? 0;
      notifyListeners();
    }
  }

  ApiResponse _couponResponse = ApiResponse(state: ResponseState.sleep, data: null);
  ApiResponse get couponResponse => _couponResponse;
  CouponModel? _coupon;
  CouponModel? get coupon => _coupon;

  void initialCoupon() {
    _couponResponse = ApiResponse(state: ResponseState.sleep, data: null);
    _coupon = null;
    notifyListeners();
  }

  Future<void> getCoupon({double? lat, double? lng}) async {
    await _fetchSingle<CouponModel>(
      apiCall: () => _get(
        Urls.couponWheels,
        query: {
          if (lat != null && lng != null) ...{'lat': lat, 'lng': lng}
        },
      ),
      mapper: (e) => CouponModel.fromJson(e),
      setResponse: (r) => _couponResponse = r,
      setValue: (v) => _coupon = v,
    );
  }

  Future<void> couponSubscribe({required int couponWheelId, required int resturantId}) async {
    Utils.loading();
    final body = FormData.fromMap({'coupon_wheel_id': couponWheelId});
    final response = await ApiHelper.instance.post(Urls.couponSubscribe, body: body);
    Utils.loadingOff();

    if (response.state == ResponseState.complete) {
      NamedNavigatorImpl.push(
        RestaurantDetailsScreen.routeName,
        arguments: RestaurantDetailsArgs(id: resturantId),
      );
    } else {
      CommonMethods.showError(message: response.data['message'], apiResponse: response);
    }
  }
}

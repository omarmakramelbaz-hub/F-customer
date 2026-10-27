import 'dart:io';

import 'package:dio/dio.dart';

import 'api_response.dart';

/// The shared request pipeline. App storage, translations and navigation are
/// supplied by the caller so this client can be exercised without the UI.
class ApiClient {
  ApiClient({
    required Dio dio,
    required Future<bool> Function() hasConnection,
    required String Function() language,
    required String? Function() token,
    required Map<String, String> Function() offlineMessage,
    required Map<String, String> Function() errorMessage,
    required void Function() onUnauthorized,
  })  : _dio = dio,
        _hasConnection = hasConnection,
        _language = language,
        _token = token,
        _offlineMessage = offlineMessage,
        _errorMessage = errorMessage,
        _onUnauthorized = onUnauthorized;

  final Dio _dio;
  final Future<bool> Function() _hasConnection;
  final String Function() _language;
  final String? Function() _token;
  final Map<String, String> Function() _offlineMessage;
  final Map<String, String> Function() _errorMessage;
  final void Function() _onUnauthorized;

  Future<ApiResponse> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    void Function()? onFinish,
    void Function(int, int)? onReceiveProgress,
    bool hasToken = true,
  }) =>
      _request(
        'GET',
        url,
        queryParameters: queryParameters,
        headers: headers,
        onFinish: onFinish,
        onReceiveProgress: onReceiveProgress,
        hasToken: hasToken,
      );

  Future<ApiResponse> post(
    String url, {
    Map<String, dynamic>? queryParameters,
    dynamic body,
    Map<String, String>? headers,
    void Function()? onFinish,
    void Function(int, int)? onReceiveProgress,
    void Function(int, int)? onSendProgress,
    bool hasToken = true,
  }) =>
      _request(
        'POST',
        url,
        queryParameters: queryParameters,
        body: body,
        headers: headers,
        onFinish: onFinish,
        onReceiveProgress: onReceiveProgress,
        onSendProgress: onSendProgress,
        hasToken: hasToken,
      );

  Future<ApiResponse> put(
    String url, {
    Map<String, dynamic>? queryParameters,
    dynamic body,
    Map<String, String>? headers,
    void Function()? onFinish,
    void Function(int, int)? onReceiveProgress,
    void Function(int, int)? onSendProgress,
    bool hasToken = true,
  }) =>
      _request(
        'PUT',
        url,
        queryParameters: queryParameters,
        body: body,
        headers: headers,
        onFinish: onFinish,
        onReceiveProgress: onReceiveProgress,
        onSendProgress: onSendProgress,
        hasToken: hasToken,
      );

  Future<ApiResponse> patch(
    String url, {
    Map<String, dynamic>? queryParameters,
    dynamic body,
    Map<String, String>? headers,
    void Function()? onFinish,
    void Function(int, int)? onReceiveProgress,
    void Function(int, int)? onSendProgress,
    bool hasToken = true,
  }) =>
      _request(
        'PATCH',
        url,
        queryParameters: queryParameters,
        body: body,
        headers: headers,
        onFinish: onFinish,
        onReceiveProgress: onReceiveProgress,
        onSendProgress: onSendProgress,
        hasToken: hasToken,
      );

  Future<ApiResponse> delete(
    String url, {
    Map<String, dynamic>? queryParameters,
    dynamic body,
    Map<String, String>? headers,
    void Function()? onFinish,
    bool hasToken = true,
  }) =>
      _request(
        'DELETE',
        url,
        queryParameters: queryParameters,
        body: body,
        headers: headers,
        onFinish: onFinish,
        hasToken: hasToken,
      );

  Options _options(String method, Map<String, String>? headers, bool hasToken) {
    final token = hasToken ? _token() : null;
    return Options(
      method: method,
      contentType: 'application/json',
      followRedirects: false,
      validateStatus: (status) => true,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Lang': _language(),
        if (token != null) 'Authorization': 'Bearer $token',
        ...?headers,
      },
    );
  }

  Future<ApiResponse> _request(
    String method,
    String url, {
    Map<String, dynamic>? queryParameters,
    dynamic body,
    Map<String, String>? headers,
    void Function()? onFinish,
    void Function(int, int)? onReceiveProgress,
    void Function(int, int)? onSendProgress,
    required bool hasToken,
  }) async {
    ApiResponse result;
    if (await _hasConnection() == false) {
      result = ApiResponse(
        state: ResponseState.offline,
        data: _offlineMessage(),
      );
    } else {
      try {
        final response = await _dio.request<dynamic>(
          url,
          queryParameters: queryParameters,
          data: body,
          options: _options(method, headers, hasToken),
          onReceiveProgress: onReceiveProgress,
          onSendProgress: onSendProgress,
        );
        result = _buildResponse(response);
      } on DioException {
        result = ApiResponse(state: ResponseState.error, data: _errorMessage());
      } on SocketException {
        result = ApiResponse(
          state: ResponseState.offline,
          data: _offlineMessage(),
        );
      }
    }

    // Preserve the existing asynchronous completion callback for every
    // normalized outcome, including offline and unsuccessful requests.
    Future<void>.delayed(Duration.zero, onFinish);
    return result;
  }

  ApiResponse _buildResponse(Response<dynamic> response) {
    final ResponseState state;
    switch (response.statusCode) {
      case 200:
      case 201:
        state = ResponseState.complete;
      case 401:
        _onUnauthorized();
        state = ResponseState.unauthorized;
      default:
        state = ResponseState.error;
    }
    return ApiResponse(state: state, data: response.data);
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:faskhaninja/helpers/networking/api_client.dart';
import 'package:faskhaninja/helpers/networking/api_response.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final bodies = <String>[];
  int status = 200;
  Object? failure;
  dynamic payload = {'data': 'ok'};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (failure != null) throw failure!;
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
    }
    bodies.add(utf8.decode(bytes));
    return ResponseBody.fromString(
      jsonEncode(payload),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _RecordingAdapter adapter;
  late ApiClient client;
  late bool connected;
  late String language;
  late String? token;
  late int unauthorizedCount;

  setUp(() {
    connected = true;
    language = 'ar';
    token = 'first-test-token';
    unauthorizedCount = 0;
    adapter = _RecordingAdapter();
    dio = Dio()..httpClientAdapter = adapter;
    client = ApiClient(
      dio: dio,
      hasConnection: () async => connected,
      language: () => language,
      token: () => token,
      offlineMessage: () => {'message': 'offline'},
      errorMessage: () => {'message': 'request failed'},
      onUnauthorized: () => unauthorizedCount++,
    );
  });

  tearDown(() => dio.close(force: true));

  Future<ApiResponse> send(
    String method, {
    dynamic body,
    Map<String, String>? headers,
    bool hasToken = true,
    void Function()? onFinish,
    void Function(int, int)? onReceiveProgress,
    void Function(int, int)? onSendProgress,
  }) {
    const url = 'https://example.invalid/orders';
    const query = {'page': 2, 'filter': 'pending'};
    switch (method) {
      case 'GET':
        return client.get(
          url,
          queryParameters: query,
          headers: headers,
          hasToken: hasToken,
          onFinish: onFinish,
          onReceiveProgress: onReceiveProgress,
        );
      case 'POST':
        return client.post(
          url,
          queryParameters: query,
          body: body,
          headers: headers,
          hasToken: hasToken,
          onFinish: onFinish,
          onReceiveProgress: onReceiveProgress,
          onSendProgress: onSendProgress,
        );
      case 'PUT':
        return client.put(
          url,
          queryParameters: query,
          body: body,
          headers: headers,
          hasToken: hasToken,
          onFinish: onFinish,
          onReceiveProgress: onReceiveProgress,
          onSendProgress: onSendProgress,
        );
      case 'PATCH':
        return client.patch(
          url,
          queryParameters: query,
          body: body,
          headers: headers,
          hasToken: hasToken,
          onFinish: onFinish,
          onReceiveProgress: onReceiveProgress,
          onSendProgress: onSendProgress,
        );
      case 'DELETE':
        return client.delete(
          url,
          queryParameters: query,
          body: body,
          headers: headers,
          hasToken: hasToken,
          onFinish: onFinish,
        );
      default:
        throw ArgumentError(method);
    }
  }

  for (final method in ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']) {
    group(method, () {
      test('preserves method, query, headers and JSON request data', () async {
        final body = method == 'GET' ? null : {'qty': 3};
        final response = await send(method, body: body);
        final request = adapter.requests.single;

        expect(request.method, method);
        expect(request.uri.queryParameters, {'page': '2', 'filter': 'pending'});
        expect(request.headers['Authorization'], 'Bearer first-test-token');
        expect(request.headers['Lang'], 'ar');
        expect(request.headers['Accept'], 'application/json');
        expect(request.contentType, 'application/json');
        expect(request.followRedirects, isFalse);
        expect(request.data, body);
        if (body != null) expect(jsonDecode(adapter.bodies.single), body);
        expect(response.state, ResponseState.complete);
        expect(response.data, {'data': 'ok'});
      });

      test('does not attach the stored token to public requests', () async {
        await send(method, hasToken: false);
        expect(adapter.requests.single.headers['Authorization'], isNull);
      });

      test(
        'offline skips transport and completes once asynchronously',
        () async {
          connected = false;
          var completions = 0;
          final response = await send(method, onFinish: () => completions++);

          expect(response.state, ResponseState.offline);
          expect(response.data, {'message': 'offline'});
          expect(adapter.requests, isEmpty);
          expect(completions, 0);
          await Future<void>.delayed(Duration.zero);
          expect(completions, 1);
        },
      );

      test('completes once asynchronously after success', () async {
        var completions = 0;
        await send(method, onFinish: () => completions++);
        expect(completions, 0);
        await Future<void>.delayed(Duration.zero);
        expect(completions, 1);
      });

      test('transport failure returns an error without retrying a write', () async {
        adapter.failure = const SocketException('unreachable');
        var completions = 0;
        final response = await send(method, onFinish: () => completions++);

        // Dio wraps adapter socket failures in DioException. Preserve the
        // existing generic-error mapping instead of changing it in a refactor.
        expect(response.state, ResponseState.error);
        expect(response.data, {'message': 'request failed'});
        expect(adapter.requests, hasLength(1));
        expect(unauthorizedCount, 0);
        expect(completions, 0);
        await Future<void>.delayed(Duration.zero);
        expect(completions, 1);
      });
    });
  }

  for (final status in [200, 201, 204, 302, 400, 401, 403, 422, 500, 503]) {
    test(
      'status $status preserves its state and the server response',
      () async {
        adapter.status = status;
        adapter.payload = {
          'message': 'server message',
          'errors': ['details'],
        };
        var completions = 0;
        final response = await client.get(
          'https://example.invalid/status',
          onFinish: () => completions++,
        );

        final expected = status == 200 || status == 201
            ? ResponseState.complete
            : status == 401
            ? ResponseState.unauthorized
            : ResponseState.error;
        expect(response.state, expected);
        expect(response.data, adapter.payload);
        expect(unauthorizedCount, status == 401 ? 1 : 0);
        expect(adapter.requests, hasLength(1));
        expect(completions, 0);
        await Future<void>.delayed(Duration.zero);
        expect(completions, 1);
      },
    );
  }

  test(
    'reads current language and token for each request, including logout',
    () async {
      await client.get('https://example.invalid/first');
      language = 'en';
      token = 'second-test-token';
      await client.get('https://example.invalid/second');
      token = null;
      await client.get('https://example.invalid/after-logout');

      expect(adapter.requests[0].headers['Lang'], 'ar');
      expect(
        adapter.requests[0].headers['Authorization'],
        'Bearer first-test-token',
      );
      expect(adapter.requests[1].headers['Lang'], 'en');
      expect(
        adapter.requests[1].headers['Authorization'],
        'Bearer second-test-token',
      );
      expect(adapter.requests[2].headers['Authorization'], isNull);
    },
  );

  test('caller headers retain precedence over default headers', () async {
    await client.get(
      'https://example.invalid/custom',
      headers: {'Lang': 'en', 'Authorization': 'custom', 'X-Request': 'test'},
    );

    final headers = adapter.requests.single.headers;
    expect(headers['Lang'], 'en');
    expect(headers['Authorization'], 'custom');
    expect(headers['X-Request'], 'test');
  });

  for (final method in ['POST', 'PUT', 'PATCH', 'DELETE']) {
    test(
      '$method preserves multipart data for cart and payment requests',
      () async {
        final form = FormData.fromMap({'qty': 2, 'payment_type': 'cash'});
        final response = await send(method, body: form);

        expect(response.state, ResponseState.complete);
        expect(adapter.requests.single.data, same(form));
        expect(
          adapter.requests.single.contentType,
          startsWith('multipart/form-data'),
        );
        expect(adapter.bodies.single, contains('name="qty"'));
        expect(adapter.bodies.single, contains('name="payment_type"'));
        expect(adapter.bodies.single, contains('cash'));
      },
    );
  }

  for (final method in ['POST', 'PUT', 'PATCH']) {
    test('$method forwards both progress callbacks', () async {
      void onSend(int count, int total) {}
      void onReceive(int count, int total) {}
      await send(
        method,
        body: {'qty': 1},
        onSendProgress: onSend,
        onReceiveProgress: onReceive,
      );

      expect(adapter.requests.single.onSendProgress, same(onSend));
      expect(adapter.requests.single.onReceiveProgress, same(onReceive));
    });
  }

  test('GET forwards download progress', () async {
    void onReceive(int count, int total) {}
    await send('GET', onReceiveProgress: onReceive);
    expect(adapter.requests.single.onReceiveProgress, same(onReceive));
  });
}

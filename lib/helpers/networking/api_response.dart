enum ResponseState {
  sleep,
  offline,
  loading,
  pagination,
  complete,
  error,
  unauthorized,
}

class ApiResponse {
  ResponseState state;
  dynamic data;

  ApiResponse({required this.state, required this.data});
}

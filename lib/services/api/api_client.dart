import 'package:dio/dio.dart';
import 'package:ledger_master/core/constants.dart';
import 'package:logger/logger.dart';

class ApiClient {
  final Dio dio;
  final Logger logger = Logger();

  ApiClient._(this.dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add common headers, auth tokens etc. (use secure storage later)
          logger.i('API Request => ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          logger.i(
            'API Response <= ${response.statusCode} ${response.requestOptions.uri}',
          );
          handler.next(response);
        },
        onError: (err, handler) {
          logger.e(
            'API Error <= ${err.response?.statusCode} ${err.requestOptions.uri}',
          );
          handler.next(err);
        },
      ),
    );
  }

  factory ApiClient.create({required String baseUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(
          milliseconds: AppConstants.apiTimeout.inMilliseconds,
        ),
        receiveTimeout: Duration(
          milliseconds: AppConstants.apiTimeout.inMilliseconds,
        ),
      ),
    );
    return ApiClient._(dio);
  }

  // Example wrapper methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
  }) {
    return dio.post(path, data: data, queryParameters: queryParameters);
  }

  // Add put/delete etc. as needed
}

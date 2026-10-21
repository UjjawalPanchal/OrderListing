import 'package:dio/dio.dart';
import 'interceptors/auth_interceptor.dart';
import 'api_constants.dart';

class DioClient {
  static final DioClient _instance = DioClient.getInstance();
  factory DioClient() => _instance;

  late final Dio dio;

  DioClient.getInstance({String? baseUrl}) {
    final options = BaseOptions(
      baseUrl: baseUrl ?? ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    dio = Dio(options);
    dio.interceptors.addAll([
      LogInterceptor(),
      AuthInterceptor(tokenProvider: () async {
        // TODO: Provide auth token here
        return null;
      }),
    ]);
  }
}
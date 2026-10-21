import 'package:demo_test_project/app/modules/order_listing/repository/order_repository.dart';
import 'package:demo_test_project/app/services/api_service.dart';

import '../core/constants/global_constants.dart';
import 'network/dio_client.dart';

class AppConfig {
  static void injectDependency() {
    getIt.registerSingleton<DioClient>(DioClient());
    getIt.registerSingleton<ApiService>(ApiService(client: getIt.get<DioClient>()));
    getIt.registerSingleton<OrderRepository>(OrderRepository());
  }
}

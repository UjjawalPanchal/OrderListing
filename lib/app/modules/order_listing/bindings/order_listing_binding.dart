import 'package:demo_test_project/app/core/constants/global_constants.dart';
import 'package:demo_test_project/app/modules/order_listing/repository/order_repository.dart';
import 'package:get/get.dart';

import '../controllers/order_listing_controller.dart';

class OrderListingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderListingController>(() => OrderListingController(repository: getIt.get<OrderRepository>()));
  }
}

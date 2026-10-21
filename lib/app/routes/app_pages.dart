import 'package:get/get.dart';

import '../modules/order_listing/bindings/order_listing_binding.dart';
import '../modules/order_listing/views/order_listing_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static final pages = <GetPage>[
    GetPage(name: AppRoutes.orderListing, page: () => const OrderListingView(), binding: OrderListingBinding()),
  ];
}

import 'dart:async';

import 'package:demo_test_project/app/modules/order_listing/repository/order_repository.dart';
import 'package:demo_test_project/task.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../models/order_model.dart';

const List<String> kSortFields = ['createdAt', 'amount', 'customer'];

class OrderListingController extends GetxController {
  final OrderRepository repository;

  OrderListingController({required this.repository});

  final orders = <OrderModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  int _currentPage = 1;
  static const int _pageSize = 20;
  final hasMore = false.obs;
  final totalOrders = 0.obs;

  final searchQuery = ''.obs;
  final selectedStatuses = <String>[].obs;
  final sortBy = kSortFields[0].obs;
  final sortOrder = 'desc'.obs;
  final TextEditingController searchController = TextEditingController();

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    searchQuery.listen((value) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () => fetchOrderData());
    });
    fetchOrderData();
  }

  void fetchNextPage() {
    if (isLoading.value || !hasMore.value) return;
    isLoadingMore.value = true;
    fetchOrderData(page: _currentPage);
  }

  void onSearch(String value) {
    searchQuery.value = value;
    if (isLoading.value || !hasMore.value) return;
    if (searchQuery.value.isNotEmpty) {
      isLoadingMore.value = true;
      fetchOrderData();
    }
  }

  void clearSearchFilter() {
    searchController.clear();
    searchQuery.value = '';
    sortBy.value = kSortFields[0];
    sortOrder.value = 'desc';
    fetchOrderData();
  }

  void onSortChanged(String field) {
    sortBy.value = field;
    sortOrder.value = sortOrder.value == 'asc' ? 'desc' : 'asc';
    fetchOrderData();
  }

  Future<void> fetchOrderData({int page = 1}) async {
    isLoading.value = true;
    isLoadingMore.value = true;
    hasError.value = false;
    errorMessage.value = '';
    if (page == 1) {
      orders.clear();
      totalOrders.value = 0;
      _currentPage = 1;
    }

    try {
      OrdersPage value = await repository.fetchOrders(
        page: page,
        limit: _pageSize,
        search: searchQuery.value,
        statuses: selectedStatuses.isEmpty ? null : selectedStatuses,
        sortBy: sortBy.value,
        sortOrder: sortOrder.value,
      );

      if (value.total != 0 && value.orders.isNotEmpty) {
        orders.addAll(value.orders);
        _currentPage++;
        hasMore.value = value.hasMore;
        totalOrders.value = value.total;
        hasError.value = false;
        errorMessage.value = '';
      } else {
        hasError.value = false;
        errorMessage.value = 'No orders found';
      }
    } on MockNetworkException catch (e) {
      hasError.value = true;
      if (e.isTimeout) {
        errorMessage.value = 'Request timed out. Please try again.';
      } else {
        errorMessage.value = 'No internet connection. Please check your network.';
      }
    } on MockApiException catch (e) {
      hasError.value = true;
      errorMessage.value = 'Server error (${e.statusCode}): ${e.message}';
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Something went wrong. Please try again.';
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchController.dispose();
    super.onClose();
  }
}

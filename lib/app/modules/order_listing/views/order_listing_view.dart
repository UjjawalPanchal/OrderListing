import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../controllers/order_listing_controller.dart';
import '../widgets/order_card.dart';
import '../widgets/sort_bottom_sheet.dart';

class OrderListingView extends GetView<OrderListingController> {
  const OrderListingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchBar(controller: controller),
          const SizedBox(height: 8),
          _ResultsHeader(controller: controller),
          Expanded(child: _OrdersBody(controller: controller)),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: false,
      title: Text('Orders', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary)),
      actions: [
        // Sort button
        Obx(() {
          final isSorted = controller.sortBy.value != 'createdAt' || controller.sortOrder.value != 'desc';
          return IconButton(
            tooltip: 'Sort',
            onPressed: SortBottomSheet.show,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.sort_rounded, color: AppColors.textPrimary),
                if (isSorted)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          );
        }),

        // Refresh button
        IconButton(
          tooltip: 'Refresh',
          onPressed: controller.fetchOrderData,
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ── Search bar ─────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final OrderListingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextFormField(
        onChanged: controller.onSearch,
        controller: controller.searchController,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search by customer, city or order ID…',
          hintStyle: AppTextStyles.bodyMedium,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
          suffixIcon: Obx(
            () => controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 20),
                    onPressed: () {
                      controller.searchController.clear();
                      controller.onSearch('');
                    },
                  )
                : const SizedBox.shrink(),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.controller});

  final OrderListingController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final total = controller.totalOrders.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Row(
          children: [
            Expanded(child: Text(total == 0 ? '' : '$total order${total == 1 ? '' : 's'} found', style: AppTextStyles.bodyMedium)),
          ],
        ),
      );
    });
  }
}

class _OrdersBody extends StatefulWidget {
  const _OrdersBody({required this.controller});

  final OrderListingController controller;

  @override
  State<_OrdersBody> createState() => _OrdersBodyState();
}

class _OrdersBodyState extends State<_OrdersBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      widget.controller.fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = widget.controller;

      if (controller.isLoading.value && controller.orders.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }
      if (controller.hasError.value && controller.orders.isEmpty) {
        return _ErrorView(message: controller.errorMessage.value, onRetry: controller.fetchOrderData);
      }
      if (controller.orders.isEmpty) {
        return _EmptyView(
          hasFilters: controller.selectedStatuses.isNotEmpty || controller.searchQuery.value.isNotEmpty,
          onReset: () => controller.clearSearchFilter(),
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.fetchOrderData,
        child: ListView.builder(
          physics: AlwaysScrollableScrollPhysics(),
          controller: _scrollController,
          padding: const EdgeInsets.only(top: 4, bottom: 24),
          itemCount: controller.orders.length + 1,
          itemBuilder: (context, index) {
            if (index < controller.orders.length) {
              return OrderCard(order: controller.orders[index]);
            } else {
              if (controller.hasError.value && controller.orders.isNotEmpty) {
                return Obx(() {
                  return _ErrorView(
                    message: controller.errorMessage.value,
                    onRetry: () {
                      controller.hasError.value = false;
                      controller.fetchNextPage();
                    },
                  );
                });
              }
              if (controller.isLoadingMore.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                );
              }
            }

            return const SizedBox.shrink();
          },
        ),
      );
    });
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to load orders',
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.hasFilters, required this.onReset});

  final bool hasFilters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilters ? 'No matching orders' : 'No orders yet',
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters ? 'Try adjusting your search or filters.' : 'When orders are placed they will appear here.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Clear Search & Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

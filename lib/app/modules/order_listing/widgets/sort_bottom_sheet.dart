// lib/app/modules/order_listing/widgets/sort_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../controllers/order_listing_controller.dart';

/// Bottom sheet that lets the user choose a sort field and direction.
class SortBottomSheet extends GetView<OrderListingController> {
  const SortBottomSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const SortBottomSheet(),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          Text('Sort Orders', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 4),
          Text('Choose how to order results', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 20),

          Obx(() {
            return Column(
              children: kSortFields.map((field) {
                final isSelected = controller.sortBy.value == field;
                final isAsc = controller.sortOrder.value == 'asc';
                return _SortTile(
                  field: field,
                  isSelected: isSelected,
                  isAsc: isAsc,
                  onTap: () {
                    controller.onSortChanged(field);
                    Get.back();
                  },
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  const _SortTile({required this.field, required this.isSelected, required this.isAsc, required this.onTap});

  final String field;
  final bool isSelected;
  final bool isAsc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = _label(field);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(_icon(field), color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 20),
      ),
      title: Text(
        label,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? Icon(isAsc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: AppColors.primary, size: 20)
          : const Icon(Icons.unfold_more_rounded, color: AppColors.textSecondary, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  String _label(String field) {
    switch (field) {
      case 'createdAt':
        return 'Date';
      case 'amount':
        return 'Amount';
      case 'customer':
        return 'Customer Name';
      default:
        return field;
    }
  }

  IconData _icon(String field) {
    switch (field) {
      case 'createdAt':
        return Icons.calendar_today_outlined;
      case 'amount':
        return Icons.currency_rupee_outlined;
      case 'customer':
        return Icons.person_outline_rounded;
      default:
        return Icons.sort_rounded;
    }
  }
}

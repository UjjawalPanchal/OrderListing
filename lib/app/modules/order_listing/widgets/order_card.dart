// lib/app/modules/order_listing/widgets/order_card.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../models/order_model.dart';

/// Maps each order status to a color used for the status badge.
Color _statusColor(String status) {
  switch (status) {
    case 'PENDING':
      return const Color(0xFFFFA726); // Orange
    case 'CONFIRMED':
      return const Color(0xFF42A5F5); // Blue
    case 'SHIPPED':
      return const Color(0xFFAB47BC); // Purple
    case 'DELIVERED':
      return const Color(0xFF66BB6A); // Green
    case 'CANCELLED':
      return const Color(0xFFEF5350); // Red
    case 'REFUNDED':
      return const Color(0xFF78909C); // Blue-Grey
    default:
      return AppColors.textSecondary;
  }
}

/// Maps each status to a compact icon.
IconData _statusIcon(String status) {
  switch (status) {
    case 'PENDING':
      return Icons.hourglass_empty_rounded;
    case 'CONFIRMED':
      return Icons.check_circle_outline_rounded;
    case 'SHIPPED':
      return Icons.local_shipping_rounded;
    case 'DELIVERED':
      return Icons.done_all_rounded;
    case 'CANCELLED':
      return Icons.cancel_outlined;
    case 'REFUNDED':
      return Icons.currency_exchange_rounded;
    default:
      return Icons.info_outline_rounded;
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.onTap});

  final OrderModel order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: Order ID + Status badge ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.id,
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  _StatusBadge(status: order.status, color: statusColor),
                ],
              ),

              const SizedBox(height: 10),

              // ── Customer info ──────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(order.customer, style: AppTextStyles.bodyLarge, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),

              if (order.customerEmail != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(order.customerEmail!, style: AppTextStyles.bodyMedium, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 4),

              // ── City ───────────────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(order.city, style: AppTextStyles.bodyMedium),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 10),

              // ── Bottom row: Amount, Items, Date ────────────────────────────
              Row(
                children: [
                  // Amount
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Amount', style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 2),
                        Text(
                          '${order.currency} ${order.amount.toStringAsFixed(2)}',
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),

                  // Item Count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Items', style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 2),
                        Text('${order.itemCount}', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                  // Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Date', style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 2),
                        Text(_formatDate(order.createdAt), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

/// Small coloured status badge pill.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}

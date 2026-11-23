import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/plant_order.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.isOwnerView = false,
    this.onMarkReady,
    this.onMarkCompleted,
  });

  final PlantOrder order;
  final bool isOwnerView;
  final VoidCallback? onMarkReady;
  final VoidCallback? onMarkCompleted;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ready for pickup':
        return AppColors.secondary;
      case 'completed':
        return AppColors.primary;
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return Colors.amber.shade800;
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'ready for pickup':
        return AppColors.soft;
      case 'completed':
        return AppColors.nurseryTint;
      case 'cancelled':
        return Colors.red.shade50;
      case 'pending':
      default:
        return Colors.amber.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final statusBg = _getStatusBg(order.status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.id,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.status,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.border, height: 20),

          // Plant Details
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.soft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_florist_rounded, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.plantName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Quantity: ${order.quantity} • ${order.paymentMethod}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Text(
                'Rs. ${order.totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Nursery & Pickup info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isOwnerView) ...[
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Text(
                        'Buyer: ${order.buyerName} (${order.buyerPhone})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    const Icon(Icons.storefront_outlined, size: 14, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Pickup: ${order.pickupAddress}',
                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (order.pickupNotes != null && order.pickupNotes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Note: "${order.pickupNotes}"',
                          style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Action Buttons for Nursery Owner
          if (isOwnerView && order.status != 'Completed' && order.status != 'Cancelled') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (order.status == 'Pending') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onMarkReady,
                      icon: const Icon(Icons.notifications_active_outlined, size: 16),
                      label: const Text('Ready for Pickup', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onMarkCompleted,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: const Text('Completed', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

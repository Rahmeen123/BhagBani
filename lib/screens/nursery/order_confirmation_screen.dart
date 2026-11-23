import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/plant_order.dart';
import '../../widgets/primary_button.dart';
import 'my_orders_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.order});

  final PlantOrder order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 12),
                    // Checkmark Graphic
                    Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.soft,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 3),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 52,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Pickup Order Created!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Order ID: ${order.id}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Order Details Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Plant Ordered', style: TextStyle(color: AppColors.muted)),
                              Text(order.plantName, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.dark)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Quantity', style: TextStyle(color: AppColors.muted)),
                              Text('${order.quantity} units', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.dark)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total to Pay', style: TextStyle(color: AppColors.muted)),
                              Text(
                                'Rs. ${order.totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Payment Mode', style: TextStyle(color: AppColors.muted)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.soft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  order.paymentMethod,
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pickup Instructions Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.directions_walk_rounded, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'How to Pick Up',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 13, color: AppColors.dark, height: 1.45),
                              children: [
                                const TextSpan(text: 'Please visit '),
                                TextSpan(text: order.nurseryName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                const TextSpan(text: ' at '),
                                TextSpan(text: order.pickupAddress, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const TextSpan(text: '. Provide your Order ID '),
                                TextSpan(text: order.id, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                                const TextSpan(text: ' and pay cash upon collecting your healthy plants.'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              PrimaryButton(
                label: 'View My Orders',
                icon: Icons.receipt_long_rounded,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const MyOrdersScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Back to Plants',
                outlined: true,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

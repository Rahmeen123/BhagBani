import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/nursery.dart';
import '../../models/plant.dart';
import '../../models/plant_order.dart';
import '../../providers/auth_scope.dart';
import '../../services/nursery_service.dart';
import '../../widgets/primary_button.dart';
import 'order_confirmation_screen.dart';

class BuyPlantScreen extends StatefulWidget {
  const BuyPlantScreen({
    super.key,
    required this.plant,
    this.nursery,
  });

  final Plant plant;
  final Nursery? nursery;

  @override
  State<BuyPlantScreen> createState() => _BuyPlantScreenState();
}

class _BuyPlantScreenState extends State<BuyPlantScreen> {
  final _service = NurseryService();
  final _notesController = TextEditingController();
  final _phoneController = TextEditingController();

  int _quantity = 1;
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = AuthScope.of(context).profile;
    if (_phoneController.text.isEmpty && user?.phone != null && user!.phone.isNotEmpty && user.phone != 'Not set') {
      _phoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _increment() {
    if (_quantity < widget.plant.quantity) {
      setState(() => _quantity++);
    }
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  Future<void> _placeOrder() async {
    setState(() => _isSubmitting = true);
    final user = AuthScope.of(context).profile;
    final total = widget.plant.price * _quantity;
    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final order = PlantOrder(
      id: orderId,
      buyerUserId: user?.email ?? 'user_anonymous',
      buyerName: user?.name.isNotEmpty == true ? user!.name : 'Baghbani Customer',
      buyerPhone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : (user?.phone ?? '0300 0000000'),
      nurseryId: widget.plant.nurseryId,
      nurseryName: widget.nursery?.nurseryName ?? widget.plant.nurseryName,
      plantId: widget.plant.id,
      plantName: widget.plant.name,
      plantImage: widget.plant.images.isNotEmpty ? widget.plant.images.first : 'plant_1',
      quantity: _quantity,
      totalPrice: total,
      paymentMethod: 'Cash on Pickup',
      status: 'Pending',
      pickupAddress: widget.nursery != null
          ? '${widget.nursery!.address}, ${widget.nursery!.city}'
          : 'Verified Nursery, Lahore',
      pickupNotes: _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    await _service.placeOrder(order);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => OrderConfirmationScreen(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;
    final total = plant.price * _quantity;
    final user = AuthScope.of(context).profile;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Checkout & Pickup'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          // Order Summary Card
          Container(
            padding: const EdgeInsets.all(18),
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
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.soft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.local_florist_rounded, color: AppColors.primary, size: 36),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.name,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.nursery?.nurseryName ?? plant.nurseryName,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rs. ${plant.price.toStringAsFixed(0)} each',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quantity Selector Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Quantity',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Max available: ${plant.quantity}',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: _decrement,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.remove, size: 18, color: AppColors.dark),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _increment,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.soft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.add, size: 18, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Payment Method: Cash on Pickup
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.soft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.payments_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.soft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Cash on Pickup',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pay at the nursery counter when collecting your plants. No advance online payment required.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pickup Location Card
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
                    Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Pickup Address',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.nursery != null
                      ? '${widget.nursery!.address}, ${widget.nursery!.city}'
                      : 'Main Road, Local Nursery Center, Lahore',
                  style: const TextStyle(fontSize: 13.5, color: AppColors.dark, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.nursery?.openingHours != null
                      ? 'Opening Hours: ${widget.nursery!.openingHours}'
                      : 'Daily: 8:00 AM - 7:00 PM',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Contact Phone & Note Input
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
                const Text(
                  'Customer Contact Phone',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'e.g. 0300 1234567',
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.muted),
                    filled: true,
                    fillColor: AppColors.cream,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Pickup Note (Optional)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g. Will collect tomorrow evening',
                    filled: true,
                    fillColor: AppColors.cream,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Price Calculation Summary Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Unit Price', style: TextStyle(color: AppColors.muted)),
                    Text('Rs. ${plant.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quantity', style: TextStyle(color: AppColors.muted)),
                    Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const Divider(color: AppColors.border, height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total to Pay on Pickup',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark),
                    ),
                    Text(
                      'Rs. ${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),

          // Place Order Button
          PrimaryButton(
            label: 'Place Pickup Order',
            icon: Icons.check_circle_rounded,
            busy: _isSubmitting,
            onPressed: _isSubmitting ? null : _placeOrder,
          ),
        ],
      ),
    );
  }
}

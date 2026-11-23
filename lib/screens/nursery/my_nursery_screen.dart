import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/nursery.dart';
import '../../models/plant.dart';
import '../../models/plant_order.dart';
import '../../services/nursery_service.dart';
import '../../widgets/primary_button.dart';
import 'add_plant_screen.dart';
import 'widgets/order_card.dart';
import 'widgets/plant_card.dart';

class MyNurseryScreen extends StatefulWidget {
  const MyNurseryScreen({super.key, required this.nursery});

  final Nursery nursery;

  @override
  State<MyNurseryScreen> createState() => _MyNurseryScreenState();
}

class _MyNurseryScreenState extends State<MyNurseryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = NurseryService();

  late Nursery _nursery;
  List<Plant> _plants = [];
  List<PlantOrder> _orders = [];
  bool _isLoading = true;

  // Edit nursery controllers
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _hoursController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSavingNursery = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _nursery = widget.nursery;
    _phoneController.text = _nursery.phone;
    _addressController.text = _nursery.address;
    _hoursController.text = _nursery.openingHours;
    _descController.text = _nursery.description;
    _loadNurseryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _hoursController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadNurseryData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _service.getPlants(nurseryId: _nursery.id),
      _service.getOrdersForNursery(_nursery.id),
      _service.getNurseryById(_nursery.id),
    ]);

    if (!mounted) return;
    setState(() {
      _plants = results[0] as List<Plant>;
      _orders = results[1] as List<PlantOrder>;
      if (results[2] != null) {
        _nursery = results[2] as Nursery;
      }
      _isLoading = false;
    });
  }

  Future<void> _deletePlant(Plant plant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Plant'),
        content: Text('Are you sure you want to remove "${plant.name}" from your nursery catalog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await _service.deletePlant(plant.id);
    _loadNurseryData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${plant.name}'),
        backgroundColor: AppColors.dark,
      ),
    );
  }

  Future<void> _updateOrderStatus(PlantOrder order, String newStatus) async {
    await _service.updateOrderStatus(order.id, newStatus);
    _loadNurseryData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ${order.id} marked as "$newStatus"'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _saveNurserySettings() async {
    setState(() => _isSavingNursery = true);
    final updated = _nursery.copyWith(
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      openingHours: _hoursController.text.trim(),
      description: _descController.text.trim(),
    );
    await _service.updateNursery(updated);

    if (!mounted) return;
    setState(() {
      _nursery = updated;
      _isSavingNursery = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nursery details updated successfully!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: Text(_nursery.nurseryName),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.dark),
            onPressed: _loadNurseryData,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'My Plants'),
            Tab(text: 'Orders'),
            Tab(text: 'Edit Nursery'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildPlantsTab(),
                _buildOrdersTab(),
                _buildEditNurseryTab(),
              ],
            ),
    );
  }

  // --------------------------------------------------
  // 1. OVERVIEW TAB
  // --------------------------------------------------
  Widget _buildOverviewTab() {
    final pendingOrders = _orders.where((o) => o.status == 'Pending').length;
    final readyOrders = _orders.where((o) => o.status == 'Ready for Pickup').length;
    final completedRevenue = _orders
        .where((o) => o.status == 'Completed')
        .fold<double>(0.0, (acc, curr) => acc + curr.totalPrice);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // Nursery Status Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sageLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Verified Nursery',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${_nursery.rating.toStringAsFixed(1)} (${_nursery.reviewsCount})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _nursery.nurseryName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_nursery.address}, ${_nursery.city}',
                style: const TextStyle(fontSize: 13, color: AppColors.sageLight),
              ),
              const SizedBox(height: 4),
              Text(
                'Hours: ${_nursery.openingHours}',
                style: const TextStyle(fontSize: 12, color: AppColors.sageLight),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Metrics Grid (2x2)
        Row(
          children: [
            _metricCard(
              title: '${_plants.length}',
              subtitle: 'Total Plants',
              icon: Icons.local_florist_rounded,
              tint: AppColors.nurseryTint,
              accent: AppColors.primary,
            ),
            const SizedBox(width: 12),
            _metricCard(
              title: '$pendingOrders',
              subtitle: 'Pending Orders',
              icon: Icons.hourglass_top_rounded,
              tint: Colors.amber.shade50,
              accent: Colors.amber.shade800,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _metricCard(
              title: '$readyOrders',
              subtitle: 'Ready for Pickup',
              icon: Icons.notifications_active_outlined,
              tint: AppColors.soft,
              accent: AppColors.secondary,
            ),
            const SizedBox(width: 12),
            _metricCard(
              title: 'Rs. ${completedRevenue.toStringAsFixed(0)}',
              subtitle: 'Completed Sales',
              icon: Icons.payments_outlined,
              tint: AppColors.farmTint,
              accent: AppColors.farmAccent,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Quick Actions
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.dark),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: 'Add Plant',
                icon: Icons.add_rounded,
                onPressed: () async {
                  final added = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute<bool>(
                      builder: (_) => AddPlantScreen(nursery: _nursery),
                    ),
                  );
                  if (added == true) _loadNurseryData();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: 'View Orders',
                outlined: true,
                icon: Icons.receipt_long_rounded,
                onPressed: () => _tabController.animateTo(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color tint,
    required Color accent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // 2. MY PLANTS TAB
  // --------------------------------------------------
  Widget _buildPlantsTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Plant', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute<bool>(
              builder: (_) => AddPlantScreen(nursery: _nursery),
            ),
          );
          if (added == true) _loadNurseryData();
        },
      ),
      body: _plants.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.soft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.yard_outlined, color: AppColors.primary, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Plants Listed Yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap "Add Plant" below to list saplings, indoor pots, and fruit trees for buyers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadNurseryData,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                itemCount: _plants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final plant = _plants[i];
                  return PlantCard(
                    plant: plant,
                    showManageActions: true,
                    onTap: () {},
                    onEdit: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute<bool>(
                          builder: (_) => AddPlantScreen(
                            nursery: _nursery,
                            plantToEdit: plant,
                          ),
                        ),
                      );
                      if (updated == true) _loadNurseryData();
                    },
                    onDelete: () => _deletePlant(plant),
                  );
                },
              ),
            ),
    );
  }

  // --------------------------------------------------
  // 3. ORDERS TAB
  // --------------------------------------------------
  Widget _buildOrdersTab() {
    return _orders.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.soft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Orders Received',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'When local plant lovers reserve plants for pickup, their orders will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        : RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _loadNurseryData,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              itemCount: _orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                final order = _orders[i];
                return OrderCard(
                  order: order,
                  isOwnerView: true,
                  onMarkReady: () => _updateOrderStatus(order, 'Ready for Pickup'),
                  onMarkCompleted: () => _updateOrderStatus(order, 'Completed'),
                );
              },
            ),
          );
  }

  // --------------------------------------------------
  // 4. EDIT NURSERY TAB
  // --------------------------------------------------
  Widget _buildEditNurseryTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      children: [
        _editLabel('Phone Number'),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.phone_outlined, color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 16),

        _editLabel('Street Address'),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 16),

        _editLabel('Opening Hours'),
        TextFormField(
          controller: _hoursController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.access_time_rounded, color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 16),

        _editLabel('About Nursery Description'),
        TextFormField(
          controller: _descController,
          maxLines: 4,
          decoration: const InputDecoration(
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 24),

        PrimaryButton(
          label: 'Save Nursery Information',
          icon: Icons.save_rounded,
          busy: _isSavingNursery,
          onPressed: _isSavingNursery ? null : _saveNurserySettings,
        ),
      ],
    );
  }

  Widget _editLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.dark),
    ),
  );
}

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/plant_order.dart';
import '../../providers/auth_scope.dart';
import '../../services/nursery_service.dart';
import '../../widgets/primary_button.dart';
import 'browse_plants_screen.dart';
import 'widgets/order_card.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final _service = NurseryService();
  List<PlantOrder> _orders = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Pending', 'Ready for Pickup', 'Completed'];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final user = AuthScope.of(context).profile;
    final userId = user?.email ?? 'demo_user';
    final list = await _service.getOrdersForUser(userId);

    if (!mounted) return;
    setState(() {
      _orders = list;
      _isLoading = false;
    });
  }

  List<PlantOrder> get _filteredOrders {
    if (_selectedFilter == 'All') return _orders;
    return _orders.where((o) => o.status.toLowerCase() == _selectedFilter.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('My Plant Orders'),
      ),
      body: Column(
        children: [
          // Filter Tabs
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final filter = _filters[i];
                final isSelected = _selectedFilter == filter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.white,
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.dark,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    setState(() => _selectedFilter = filter);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredOrders.isEmpty
                    ? _emptyOrders()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadOrders,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                          itemCount: _filteredOrders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, i) {
                            return OrderCard(order: _filteredOrders[i]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _emptyOrders() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: AppColors.soft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 38),
          ),
          const SizedBox(height: 18),
          const Text(
            'No Orders Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.dark),
          ),
          const SizedBox(height: 8),
          const Text(
            'You haven’t placed any plant pickup orders yet. Browse nurseries near you to reserve plants.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 13.5, height: 1.45),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Browse Plants',
            icon: Icons.search_rounded,
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(builder: (_) => const BrowsePlantsScreen()),
              );
            },
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/nursery.dart';
import '../../models/plant.dart';
import '../../services/nursery_service.dart';
import '../../widgets/primary_button.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({
    super.key,
    required this.nursery,
    this.plantToEdit,
  });

  final Nursery nursery;
  final Plant? plantToEdit;

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _form = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scientificController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '10');
  final _heightController = TextEditingController(text: '2 - 3 Feet');
  final _descriptionController = TextEditingController();
  final _service = NurseryService();

  String _selectedCategory = 'Indoor';
  bool _availability = true;
  bool _isSaving = false;

  final List<String> _categories = [
    'Indoor',
    'Outdoor',
    'Fruit Trees',
    'Flowering',
    'Succulents',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.plantToEdit != null) {
      final p = widget.plantToEdit!;
      _nameController.text = p.name;
      _scientificController.text = p.scientificName;
      _priceController.text = p.price.toStringAsFixed(0);
      _quantityController.text = p.quantity.toString();
      _heightController.text = p.height;
      _descriptionController.text = p.description;
      _selectedCategory = p.category;
      _availability = p.availability;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scientificController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _heightController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _savePlant() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final isEdit = widget.plantToEdit != null;
    final plantId = isEdit
        ? widget.plantToEdit!.id
        : 'plant_${DateTime.now().millisecondsSinceEpoch}';

    final plant = Plant(
      id: plantId,
      nurseryId: widget.nursery.id,
      nurseryName: widget.nursery.nurseryName,
      name: _nameController.text.trim(),
      scientificName: _scientificController.text.trim().isNotEmpty
          ? _scientificController.text.trim()
          : _nameController.text.trim(),
      category: _selectedCategory,
      price: double.tryParse(_priceController.text.trim()) ?? 500,
      quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
      height: _heightController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : 'Healthy, acclimatized nursery plant grown under expert horticultural supervision.',
      images: ['plant_custom'],
      availability: _availability,
      rating: widget.plantToEdit?.rating ?? 4.9,
      createdAt: widget.plantToEdit?.createdAt ?? DateTime.now(),
    );

    if (isEdit) {
      await _service.updatePlant(plant);
    } else {
      await _service.addPlant(plant);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEdit ? 'Plant updated successfully!' : 'Plant added to nursery inventory!'),
        backgroundColor: AppColors.primary,
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.plantToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: Text(isEdit ? 'Edit Plant' : 'Add New Plant'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            // Category Selector Chips
            _label('Plant Category *'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
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
                    if (val) setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            _label('Plant Common Name *'),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Ficus Lyrata (Fiddle Leaf Fig)',
                prefixIcon: Icon(Icons.local_florist_outlined, color: AppColors.muted),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter plant common name' : null,
            ),
            const SizedBox(height: 16),

            _label('Scientific / Botanical Name'),
            TextFormField(
              controller: _scientificController,
              decoration: const InputDecoration(
                hintText: 'e.g. Ficus lyrata',
                prefixIcon: Icon(Icons.psychology_alt_outlined, color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Price (Rs.) *'),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 850',
                          prefixIcon: Icon(Icons.payments_outlined, color: AppColors.muted),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter price';
                          if (double.tryParse(v) == null) return 'Invalid price';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Stock Quantity *'),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 25',
                          prefixIcon: Icon(Icons.inventory_2_outlined, color: AppColors.muted),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter stock';
                          if (int.tryParse(v) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _label('Plant Height / Size'),
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(
                hintText: 'e.g. 2 - 3 Feet (Potted)',
                prefixIcon: Icon(Icons.height_rounded, color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 16),

            _label('Plant Description & Care Instructions'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe foliage, sunlight requirements, watering tips, and root health…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Availability Switch Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available in Stock',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      Text(
                        'Visible to plant buyers in catalog',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: _availability,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _availability = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            PrimaryButton(
              label: isEdit ? 'Save Changes' : 'Add Plant to Catalog',
              icon: Icons.save_rounded,
              busy: _isSaving,
              onPressed: _isSaving ? null : _savePlant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: AppColors.dark,
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../widgets/primary_button.dart';
import '../models/plant_recommendation.dart';
import '../screens/plant_health_result_screen.dart';
import 'plant_health_image_picker.dart';

class PlantHealthActionButton extends StatelessWidget {
  const PlantHealthActionButton({
    super.key,
    required this.recommendation,
    this.picker,
  });

  final PlantRecommendation recommendation;
  final ImagePicker? picker;

  Future<void> _openPicker(BuildContext context) async {
    final file = await PlantHealthImagePicker(picker: picker).pick(context);
    if (file == null || !context.mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PlantHealthResultScreen(
          plant: recommendation.plant,
          image: file,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!recommendation.plant.healthSupported) return const SizedBox.shrink();
    return PrimaryButton(
      label: 'Check Health',
      icon: Icons.health_and_safety_outlined,
      height: 44,
      borderRadius: 14,
      onPressed: () => _openPicker(context),
    );
  }
}

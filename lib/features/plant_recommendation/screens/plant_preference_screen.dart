import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/primary_button.dart';
import '../models/plant_preferences.dart';
import '../widgets/plant_widgets.dart';
import 'plant_recommendation_result_screen.dart';

class PlantPreferenceScreen extends StatefulWidget {
  const PlantPreferenceScreen({super.key});

  @override
  State<PlantPreferenceScreen> createState() => _PlantPreferenceScreenState();
}

class _PlantPreferenceScreenState extends State<PlantPreferenceScreen> {
  SunlightPreference? _sunlight;
  WateringPreference? _watering;
  bool _knowsSoil = false;
  PlantSoilType? _soilType;
  GrowthPreference _growth = GrowthPreference.noPreference;
  bool _showValidationErrors = false;

  void _submit() {
    if (_sunlight == null || _watering == null) {
      setState(() => _showValidationErrors = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please choose your sunlight spot and care level to continue.',
          ),
          backgroundColor: AppColors.gardenAccent,
        ),
      );
      return;
    }

    final preferences = PlantPreferences(
      sunlight: _sunlight!,
      watering: _watering!,
      soilType: _knowsSoil ? _soilType : null,
      growth: _growth,
    );

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PlantRecommendationResultScreen(
          preferences: preferences,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PlantScreenScaffold(
        title: 'Plant Preferences',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const Text(
              'Tell us about your space',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'We will match home plants to your light and watering routine.',
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),

            // 1. Sunlight (Required)
            _QuestionHeader(
              question: 'Where will you place your plant?',
              requiredField: true,
              hasError: _showValidationErrors && _sunlight == null,
              errorText: 'Please select a sunlight option.',
            ),
            const SizedBox(height: 10),
            for (final option in SunlightPreference.values)
              PlantPreferenceOptionCard(
                emoji: option.emoji,
                title: option.title,
                subtitle: option.description,
                selected: _sunlight == option,
                onTap: () => setState(() => _sunlight = option),
              ),
            const SizedBox(height: 14),

            // 2. Watering Preference (Required)
            _QuestionHeader(
              question: 'How much care can you provide?',
              requiredField: true,
              hasError: _showValidationErrors && _watering == null,
              errorText: 'Please select a care level.',
            ),
            const SizedBox(height: 10),
            for (final option in WateringPreference.values)
              PlantPreferenceOptionCard(
                emoji: option.emoji,
                title: option.title,
                subtitle: option.description,
                selected: _watering == option,
                onTap: () => setState(() => _watering = option),
              ),
            const SizedBox(height: 14),

            // 3. Soil Type (Optional)
            const _QuestionHeader(
              question: 'Do you know your soil type?',
              requiredField: false,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _BinaryChoiceButton(
                    label: 'Yes',
                    selected: _knowsSoil,
                    onTap: () => setState(() {
                      _knowsSoil = true;
                      _soilType ??= PlantSoilType.wellDrained;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BinaryChoiceButton(
                    label: 'No',
                    selected: !_knowsSoil,
                    onTap: () => setState(() {
                      _knowsSoil = false;
                      _soilType = null;
                    }),
                  ),
                ),
              ],
            ),
            if (_knowsSoil) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final soil in PlantSoilType.values)
                    ChoiceChip(
                      label: Text(soil.datasetValue),
                      selected: _soilType == soil,
                      selectedColor: AppColors.soft,
                      labelStyle: TextStyle(
                        color: _soilType == soil
                            ? AppColors.primary
                            : AppColors.dark,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: _soilType == soil
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                      onSelected: (_) => setState(() => _soilType = soil),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 22),

            // 4. Growth Preference (Optional)
            const _QuestionHeader(
              question: 'What type of growth do you prefer?',
              requiredField: false,
            ),
            const SizedBox(height: 10),
            for (final option in GrowthPreference.values)
              PlantPreferenceOptionCard(
                title: option.label,
                selected: _growth == option,
                onTap: () => setState(() => _growth = option),
              ),
            const SizedBox(height: 18),

            PrimaryButton(
              label: 'Get Recommendations',
              icon: Icons.auto_awesome_rounded,
              onPressed: _submit,
            ),
          ],
        ),
      );
}

class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({
    required this.question,
    required this.requiredField,
    this.hasError = false,
    this.errorText,
  });

  final String question;
  final bool requiredField;
  final bool hasError;
  final String? errorText;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: requiredField
                      ? AppColors.gardenTint
                      : AppColors.sageLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  requiredField ? 'Required' : 'Optional',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: requiredField
                        ? AppColors.gardenAccent
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (hasError && errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              errorText!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.gardenAccent,
              ),
            ),
          ],
        ],
      );
}

class _BinaryChoiceButton extends StatelessWidget {
  const _BinaryChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: selected ? AppColors.soft : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppColors.primary : AppColors.muted,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ),
      );
}

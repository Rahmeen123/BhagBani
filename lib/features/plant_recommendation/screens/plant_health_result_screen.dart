import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/primary_button.dart';
import '../models/plant.dart';
import '../models/plant_health_analysis.dart';
import '../services/plant_health_api_service.dart';
import '../widgets/plant_health_image_picker.dart';
import '../widgets/plant_widgets.dart';

class PlantHealthResultScreen extends StatefulWidget {
  PlantHealthResultScreen({
    super.key,
    required this.plant,
    required this.image,
    PlantHealthApiService? service,
  }) : service = service ?? PlantHealthApiService();

  final Plant plant;
  final XFile image;
  final PlantHealthApiService service;

  @override
  State<PlantHealthResultScreen> createState() =>
      _PlantHealthResultScreenState();
}

class _PlantHealthResultScreenState extends State<PlantHealthResultScreen> {
  late Future<PlantHealthAnalysis> _analysis;
  late Future<Uint8List> _imageBytes;

  @override
  void initState() {
    super.initState();
    _analysis = _runAnalysis();
    _imageBytes = widget.image.readAsBytes();
  }

  Future<PlantHealthAnalysis> _runAnalysis() => widget.service.analyze(
        image: widget.image,
        plantName: widget.plant.name,
      );

  void _retry() {
    setState(() => _analysis = _runAnalysis());
  }

  Future<void> _chooseAnotherPhoto() async {
    final image = await const PlantHealthImagePicker().pick(context);
    if (image == null || !mounted) return;
    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) => PlantHealthResultScreen(
          plant: widget.plant,
          image: image,
          service: widget.service,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PlantScreenScaffold(
        title: 'Plant Health Result',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            FutureBuilder<Uint8List>(
              future: _imageBytes,
              builder: (context, snapshot) => Container(
                height: 210,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.gardenTint,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: snapshot.hasData
                    ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                    : const Center(
                        child: Icon(
                          Icons.local_florist_rounded,
                          size: 54,
                          color: AppColors.gardenAccent,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.plant.name,
              style: const TextStyle(
                color: AppColors.dark,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            FutureBuilder<PlantHealthAnalysis>(
              future: _analysis,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _RetryCard(
                    message: snapshot.error.toString(),
                    onRetry: _retry,
                  );
                }
                if (!snapshot.hasData) {
                  return const PlantInfoCard(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Checking plant health...',
                            style: TextStyle(
                              color: AppColors.dark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return _AnalysisCard(
                  analysis: snapshot.data!,
                  onChooseAnotherPhoto: _chooseAnotherPhoto,
                );
              },
            ),
          ],
        ),
      );
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.analysis,
    required this.onChooseAnotherPhoto,
  });

  final PlantHealthAnalysis analysis;
  final VoidCallback onChooseAnotherPhoto;

  @override
  Widget build(BuildContext context) {
    final color = analysis.isHealthy
        ? AppColors.primary
        : analysis.needsRetake
            ? AppColors.farmAccent
            : AppColors.gardenAccent;
    final icon = analysis.isHealthy
        ? Icons.check_circle_outline_rounded
        : analysis.needsRetake
            ? Icons.photo_camera_back_outlined
            : Icons.warning_amber_rounded;
    final heading = analysis.needsRetake
        ? 'Photo needs another look'
        : analysis.isHealthy
            ? 'Plant looks healthy'
            : 'Plant health concern';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlantInfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      heading,
                      style: TextStyle(
                        color: color,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (analysis.message != null) ...[
                const SizedBox(height: 12),
                Text(
                  analysis.message!,
                  style: const TextStyle(
                    color: AppColors.dark,
                    height: 1.4,
                  ),
                ),
              ],
              if (analysis.label != null) ...[
                const SizedBox(height: 12),
                Text(
                  analysis.label!,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (analysis.confidence != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Confidence: ${(analysis.confidence! * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                ),
              ],
              for (final tip in analysis.treatmentTips) ...[
                const SizedBox(height: 10),
                Text(
                  '• $tip',
                  style: const TextStyle(
                    color: AppColors.dark,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        PlantInfoCard(
          padding: const EdgeInsets.all(14),
          child: Text(
            analysis.disclaimer,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ),
        if (analysis.needsRetake) ...[
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Choose Another Photo',
            icon: Icons.refresh_rounded,
            onPressed: onChooseAnotherPhoto,
          ),
        ],
      ],
    );
  }
}

class _RetryCard extends StatelessWidget {
  const _RetryCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => PlantInfoCard(
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.gardenAccent,
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.dark,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/land_analysis_request.dart';
import '../models/land_analysis_result.dart';
import '../repository/satellite_analysis_repository.dart';
import '../services/satellite_analysis_api_service.dart';
import 'satellite_analysis_result_screen.dart';

class SatelliteAnalysisLoadingScreen extends StatefulWidget {
  const SatelliteAnalysisLoadingScreen({
    super.key,
    required this.request,
    this.repository,
  });

  final LandAnalysisRequest request;
  final SatelliteAnalysisRepository? repository;

  @override
  State<SatelliteAnalysisLoadingScreen> createState() =>
      _SatelliteAnalysisLoadingScreenState();
}

class _SatelliteAnalysisLoadingScreenState
    extends State<SatelliteAnalysisLoadingScreen> {
  late final Future<LandAnalysisResult> _analysis;
  late final SatelliteAnalysisRepository _repository;
  late final bool _ownsRepository;

  @override
  void initState() {
    super.initState();
    _ownsRepository = widget.repository == null;
    _repository = widget.repository ?? SatelliteAnalysisRepository();
    _analysis = _repository.analyze(widget.request);
  }

  @override
  void dispose() {
    if (_ownsRepository) _repository.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<LandAnalysisResult>(
        future: _analysis,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              backgroundColor: AppColors.cream,
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Analyzing your land',
                          style: TextStyle(
                            color: AppColors.dark,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Checking recent Sentinel-2 imagery for vegetation and cloud cover.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          final error = snapshot.error;
          final result = snapshot.hasData
              ? snapshot.data!
              : LandAnalysisResult.inconclusive(
                  message: error is SatelliteAnalysisApiException
                      ? error.message
                      : 'The satellite service could not complete this analysis. Try again later.',
                );
          return SatelliteAnalysisResultScreen(result: result);
        },
      );
}

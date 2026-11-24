import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/farmer.dart';
import '../../models/land_application.dart';
import '../../services/farmer_service.dart';
import '../../widgets/primary_button.dart';

class ApplicantProfileScreen extends StatefulWidget {
  const ApplicantProfileScreen({super.key, required this.application});

  final LandApplication application;

  @override
  State<ApplicantProfileScreen> createState() => _ApplicantProfileScreenState();
}

class _ApplicantProfileScreenState extends State<ApplicantProfileScreen> {
  final _service = FarmerService();
  late final Future<Farmer> _farmer = _loadFarmer();

  Future<Farmer> _loadFarmer() async {
    final farmers = await _service.getFarmers();
    for (final farmer in farmers) {
      if (farmer.userId == widget.application.farmerUserId) return farmer;
    }

    final application = widget.application;
    final years = RegExp(r'\d+').firstMatch(application.experience)?.group(0);
    return Farmer(
      id: application.farmerUserId,
      userId: application.farmerUserId,
      name: application.farmerName,
      location: application.location,
      experienceYears: int.tryParse(years ?? '') ?? 0,
      skills: application.skills.isEmpty ? const [] : [application.skills],
      services: const [],
      availability: true,
      rating: 0,
      description: application.message,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          title: const Text('Farmer Profile'),
        ),
        body: FutureBuilder<Farmer>(
          future: _farmer,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    'Could not load farmer profile: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final farmer = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: AppColors.farmTint,
                        backgroundImage: farmer.profileImage != null &&
                                farmer.profileImage!.startsWith('http')
                            ? NetworkImage(farmer.profileImage!)
                            : null,
                        child: farmer.profileImage != null &&
                                farmer.profileImage!.startsWith('http')
                            ? null
                            : Text(
                                farmer.name.isEmpty
                                    ? 'F'
                                    : farmer.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.farmAccent,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        farmer.name,
                        style: const TextStyle(
                          color: AppColors.dark,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      _location(farmer.location),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _info(
                  'Experience',
                  '${farmer.experienceYears} years',
                  Icons.work_history_outlined,
                ),
                _info(
                  'Skills',
                  farmer.skills.isEmpty
                      ? 'Not provided'
                      : farmer.skills.join(', '),
                  Icons.grass_outlined,
                ),
                _info(
                  'Services',
                  farmer.services.isEmpty
                      ? 'Not provided'
                      : farmer.services.join(', '),
                  Icons.handyman_outlined,
                ),
                _info(
                  'Availability',
                  farmer.availability ? 'Available' : 'Not available',
                  Icons.event_available_outlined,
                ),
                _info(
                  'About Me',
                  farmer.description.isEmpty
                      ? 'No profile introduction provided.'
                      : farmer.description,
                  Icons.person_outline_rounded,
                ),
                _info(
                  'Rating',
                  farmer.rating == 0
                      ? 'New farmer'
                      : '${farmer.rating.toStringAsFixed(1)} (${farmer.reviewsCount} reviews)',
                  Icons.star_outline_rounded,
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Back',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        ),
      );

  Widget _location(String location) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_on_outlined,
              size: 16, color: AppColors.muted),
          const SizedBox(width: 4),
          Text(
            location.isEmpty ? 'Location not provided' : location,
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
        ],
      );

  Widget _info(String title, String value, IconData icon) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.farmAccent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                        color: AppColors.dark, fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/farmer.dart';
import '../../navigation/protected_feature_navigation.dart';
import '../../providers/auth_scope.dart';
import '../../widgets/primary_button.dart';
import '../auth/login_screen.dart';
import 'hiring_request_screen.dart';

class FarmerProfileScreen extends StatelessWidget {
  const FarmerProfileScreen({super.key, required this.farmer});

  final Farmer farmer;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final isGuest = auth.isGuest || (auth.profile?.isGuest ?? false);

    final initials = farmer.name
        .trim()
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Farmer Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
        children: [
          // Header Card with Avatar & Primary Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.soft,
                  child: Text(
                    initials.isEmpty ? 'F' : initials,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  farmer.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      farmer.location,
                      style: const TextStyle(fontSize: 14, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stat Cards (Rating, Experience, Availability)
                Row(
                  children: [
                    _statBox(
                      icon: Icons.star_rounded,
                      iconColor: Colors.amber,
                      title: farmer.rating.toStringAsFixed(1),
                      subtitle: '${farmer.reviewsCount} Reviews',
                    ),
                    const SizedBox(width: 10),
                    _statBox(
                      icon: Icons.work_history_outlined,
                      iconColor: AppColors.secondary,
                      title: '${farmer.experienceYears} Years',
                      subtitle: 'Experience',
                    ),
                    const SizedBox(width: 10),
                    _statBox(
                      icon: farmer.availability ? Icons.check_circle_outline : Icons.schedule,
                      iconColor: farmer.availability ? AppColors.primary : Colors.orange,
                      title: farmer.availability ? 'Available' : 'Busy',
                      subtitle: 'Current Status',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // About / Description Card
          _infoCard(
            title: 'About Farmer',
            icon: Icons.person_outline_rounded,
            child: Text(
              farmer.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.dark,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Farming Skills Card
          _infoCard(
            title: 'Farming Skills',
            icon: Icons.psychology_outlined,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: farmer.skills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Available Services Card
          _infoCard(
            title: 'Available Services',
            icon: Icons.handyman_outlined,
            child: Column(
              children: farmer.services.map((svc) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.nurseryTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.eco_rounded, size: 14, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          svc,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Rate & Working Terms Note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.soft.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined, color: AppColors.primary, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimated Rate',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                      Text(
                        farmer.dailyRate,
                        style: const TextStyle(
                          fontSize: 16,
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
        ],
      ),

      // Bottom Bar with "Hire Farmer" Button
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: PrimaryButton(
          label: 'Hire Farmer',
          icon: Icons.send_rounded,
          onPressed: () => ProtectedFeatureNavigation.open(
            context,
            destination: (_) => HiringRequestScreen(farmer: farmer),
            loginScreenBuilder: (destination) =>
                LoginScreen(onAuthenticated: destination),
          ),
        ),
      ),
    );
  }

  Widget _statBox({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );

  Widget _infoCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 19, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

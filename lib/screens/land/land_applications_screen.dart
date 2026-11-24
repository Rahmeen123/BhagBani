import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/farmer.dart';
import '../../models/land.dart';
import '../../models/land_application.dart';
import '../../services/farmer_service.dart';
import '../../services/land_service.dart';
import '../../widgets/primary_button.dart';
import 'applicant_profile_screen.dart';

class LandApplicationsScreen extends StatefulWidget {
  const LandApplicationsScreen({
    super.key,
    required this.land,
    required this.ownerUserId,
  });

  final Land land;
  final String ownerUserId;

  @override
  State<LandApplicationsScreen> createState() => _LandApplicationsScreenState();
}

class _LandApplicationsScreenState extends State<LandApplicationsScreen> {
  final _service = LandService();
  late Future<List<({Land land, LandApplication application})>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<({Land land, LandApplication application})>> _load() {
    return _service.getApplicationsForLand(
      widget.land.id,
      ownerUserId: widget.ownerUserId,
    );
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _updateStatus(String applicationId, String status) async {
    try {
      await _service.updateApplicationStatus(
        applicationId,
        status,
        ownerUserId: widget.ownerUserId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application marked as $status.'),
          backgroundColor: status == LandApplication.accepted
              ? AppColors.farmAccent
              : AppColors.gardenAccent,
        ),
      );
      _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update application: $error')),
      );
    }
  }

  void _viewProfile(LandApplication application) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ApplicantProfileScreen(application: application),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Applications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.land.landName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<({Land land, LandApplication application})>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _emptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load applications',
              detail: snapshot.error.toString(),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return _emptyState(
              icon: Icons.inbox_outlined,
              title: 'No applications yet',
              detail:
                  'Farmers who apply for "${widget.land.landName}" will appear here.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            children: [
              // Summary banner
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.farmTint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.assignment_ind_outlined,
                        color: AppColors.farmAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${items.length} ${items.length == 1 ? 'Applicant' : 'Applicants'} for this land',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Review farmer profiles and accept or reject applications.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              for (final item in items)
                _ApplicationCard(
                  application: item.application,
                  land: item.land,
                  onViewProfile: () => _viewProfile(item.application),
                  onAccept: () => _updateStatus(
                    item.application.id,
                    LandApplication.accepted,
                  ),
                  onReject: () => _updateStatus(
                    item.application.id,
                    LandApplication.rejected,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String detail,
  }) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.farmAccent, size: 48),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.land,
    required this.onViewProfile,
    required this.onAccept,
    required this.onReject,
  });

  final LandApplication application;
  final Land land;
  final VoidCallback onViewProfile;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final isPending = application.status == LandApplication.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Farmer Photo, Name, and Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FarmerAvatar(
                userId: application.farmerUserId,
                name: application.farmerName,
                photoUrl: application.farmerPhoto,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.farmerName,
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Applied ${_formatDate(application.createdAt)}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: application.status),
            ],
          ),
          const SizedBox(height: 14),

          // Experience
          if (application.experience.isNotEmpty) ...[
            _detailRow(
              icon: Icons.work_outline_rounded,
              label: 'Experience',
              value: application.experience,
            ),
            const SizedBox(height: 8),
          ],

          // Skills
          if (application.skills.isNotEmpty) ...[
            _detailRow(
              icon: Icons.stars_outlined,
              label: 'Skills',
              value: application.skills,
            ),
            const SizedBox(height: 8),
          ],

          // Location
          if (application.location.isNotEmpty) ...[
            _detailRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: application.location,
            ),
            const SizedBox(height: 8),
          ],

          // Message
          if (application.message.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 14,
                        color: AppColors.muted,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    application.message,
                    style: const TextStyle(
                      color: AppColors.dark,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Action Button: View Profile
          OutlinedButton.icon(
            onPressed: onViewProfile,
            icon: const Icon(Icons.person_outline_rounded),
            label: const Text('View Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(44),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          // Accept / Reject Buttons
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: application.status == LandApplication.accepted
                      ? 'Accepted'
                      : 'Accept',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: isPending ? onAccept : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: application.status == LandApplication.rejected
                      ? 'Rejected'
                      : 'Reject',
                  outlined: true,
                  icon: Icons.cancel_outlined,
                  onPressed: isPending ? onReject : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.farmAccent),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ),
        ],
      );

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _FarmerAvatar extends StatefulWidget {
  const _FarmerAvatar({
    required this.userId,
    required this.name,
    this.photoUrl,
  });

  final String userId;
  final String name;
  final String? photoUrl;

  @override
  State<_FarmerAvatar> createState() => _FarmerAvatarState();
}

class _FarmerAvatarState extends State<_FarmerAvatar> {
  late Future<String?> _photoFuture;

  @override
  void initState() {
    super.initState();
    _photoFuture = _resolvePhoto();
  }

  Future<String?> _resolvePhoto() async {
    if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty) {
      return widget.photoUrl;
    }
    final farmers = await FarmerService().getFarmers();
    for (final farmer in farmers) {
      if (farmer.userId == widget.userId && farmer.profileImage != null) {
        return farmer.profileImage;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _photoFuture,
      builder: (context, snapshot) {
        final photo = snapshot.data ?? widget.photoUrl;
        final hasImage = photo != null && photo.startsWith('http');

        return CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.farmTint,
          backgroundImage: hasImage ? NetworkImage(photo) : null,
          child: hasImage
              ? null
              : Text(
                  widget.name.isEmpty ? 'F' : widget.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.farmAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color text) = switch (status) {
      LandApplication.accepted => (
          AppColors.farmTint,
          AppColors.farmAccent,
        ),
      LandApplication.rejected => (
          const Color(0xFFFFEBEE),
          const Color(0xFFE53935),
        ),
      _ => (
          AppColors.communityTint,
          AppColors.communityAccent,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

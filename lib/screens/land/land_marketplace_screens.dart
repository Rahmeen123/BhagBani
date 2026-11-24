import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/farmer.dart';
import '../../models/land.dart';
import '../../models/land_application.dart';
import '../../providers/auth_scope.dart';
import '../../services/farmer_service.dart';
import '../../services/land_service.dart';
import '../../widgets/primary_button.dart';
import 'applicant_profile_screen.dart';
import '../farmer/widgets/community_login_gate.dart';

class FindLandScreen extends StatefulWidget {
  const FindLandScreen({super.key});

  @override
  State<FindLandScreen> createState() => _FindLandScreenState();
}

class _FindLandScreenState extends State<FindLandScreen> {
  final _service = LandService();
  final _searchController = TextEditingController();
  late Future<List<Land>> _landsFuture;
  String? _location;
  String? _area;
  String? _crop;
  String? _water;

  @override
  void initState() {
    super.initState();
    _landsFuture = _service.getLands();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openApplications() {
    openCommunityFeature(
      context,
      destination: (_) => MyAppliedLandsScreen(
        farmerUserId: AuthScope.of(context).profile?.email ?? '',
      ),
    );
  }

  void _openReceived() {
    openCommunityFeature(
      context,
      destination: (_) => MyLandApplicationsScreen(
        ownerUserId: AuthScope.of(context).profile?.email ?? '',
      ),
    );
  }

  Future<void> _openLand(Land land) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LandDetailScreen(land: land, service: _service),
      ),
    );
  }

  bool _matches(Land land) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty && !land.landName.toLowerCase().contains(query)) {
      return false;
    }
    if (_location != null && land.location != _location) return false;
    if (_crop != null && land.preferredCrop != _crop) return false;
    if (_water != null && land.waterSource != _water) return false;
    if (_area == 'Under 5 acres' && land.area >= 5) return false;
    if (_area == '5-20 acres' && (land.area < 5 || land.area > 20)) {
      return false;
    }
    if (_area == 'Over 20 acres' && land.area <= 20) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final isGuest = auth.isGuest || (auth.profile?.isGuest ?? false);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: const Text('Find Land'),
        actions: [
          if (!isGuest) ...[
            IconButton(
              tooltip: 'My applications',
              onPressed: _openApplications,
              icon: const Icon(Icons.assignment_outlined),
            ),
            IconButton(
              tooltip: 'My land listings',
              onPressed: () => Navigator.pushNamed(
                context,
                '/my-land-listings',
                arguments: AuthScope.of(context).profile?.email ?? '',
              ),
              icon: const Icon(Icons.landscape_outlined),
            ),
            IconButton(
              tooltip: 'Applications received',
              onPressed: _openReceived,
              icon: const Icon(Icons.inbox_outlined),
            ),
          ],
        ],
      ),
      body: FutureBuilder<List<Land>>(
        future: _landsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LoadMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load land listings',
              detail: snapshot.error.toString(),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final available = snapshot.data!
              .where((land) => land.status.toLowerCase() == 'available')
              .toList();
          final filtered = available.where(_matches).toList();
          final locations =
              available.map((land) => land.location).toSet().toList()..sort();
          final crops = available
              .map((land) => land.preferredCrop)
              .toSet()
              .toList()
            ..sort();
          final waters = available
              .map((land) => land.waterSource)
              .toSet()
              .toList()
            ..sort();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.agriculture_rounded,
                        color: AppColors.farmAccent, size: 34),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grow something great',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Explore farmland shared by owners and find the right opportunity.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.muted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search land by name',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _filter<String>(
                    label: 'Location',
                    value: _location,
                    options: locations,
                    onChanged: (value) => setState(() => _location = value),
                  ),
                  _filter<String>(
                    label: 'Preferred crop',
                    value: _crop,
                    options: crops,
                    onChanged: (value) => setState(() => _crop = value),
                  ),
                  _filter<String>(
                    label: 'Water source',
                    value: _water,
                    options: waters,
                    onChanged: (value) => setState(() => _water = value),
                  ),
                  _filter<String>(
                    label: 'Area',
                    value: _area,
                    options: const [
                      'Under 5 acres',
                      '5-20 acres',
                      'Over 20 acres'
                    ],
                    onChanged: (value) => setState(() => _area = value),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '${filtered.length} available ${filtered.length == 1 ? 'land' : 'lands'}',
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (filtered.isEmpty)
                const _LoadMessage(
                  icon: Icons.search_off_rounded,
                  title: 'No matching land found',
                  detail: 'Try adjusting your search or filters.',
                )
              else
                ...filtered.map(
                  (land) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _LandCard(land: land, onView: () => _openLand(land)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class LandDetailScreen extends StatelessWidget {
  const LandDetailScreen({
    super.key,
    required this.land,
    required this.service,
  });

  final Land land;
  final LandService service;

  void _apply(BuildContext context) {
    openCommunityFeature(
      context,
      destination: (_) {
        final profile = AuthScope.of(context).profile;
        return ApplyLandScreen(
          land: land,
          service: service,
          farmerUserId: profile?.email ?? '',
          farmerName: profile?.name ?? 'Farmer',
          farmerLocation: profile?.location ?? '',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
          backgroundColor: AppColors.cream, title: const Text('Land Details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _LandGallery(land: land, height: 230),
          const SizedBox(height: 18),
          Text(
            land.landName,
            style: const TextStyle(
              color: AppColors.dark,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          _DetailLine(icon: Icons.location_on_outlined, text: land.location),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                icon: Icons.square_foot_rounded,
                text: _areaText(land),
              ),
              _InfoChip(icon: Icons.grass_rounded, text: land.preferredCrop),
              _InfoChip(
                  icon: Icons.water_drop_outlined, text: land.waterSource),
              _InfoChip(icon: Icons.terrain_rounded, text: land.soilType),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle('About this land'),
          const SizedBox(height: 8),
          Text(
            land.description,
            style: const TextStyle(
                color: AppColors.muted, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 22),
          const _SectionTitle('Land owner'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.farmTint,
                  child: Icon(Icons.person_outline_rounded,
                      color: AppColors.farmAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    land.ownerName,
                    style: const TextStyle(
                      color: AppColors.dark,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Apply Now', onPressed: () => _apply(context)),
        ],
      ),
    );
  }
}

class ApplyLandScreen extends StatefulWidget {
  const ApplyLandScreen({
    super.key,
    required this.land,
    required this.service,
    required this.farmerUserId,
    required this.farmerName,
    required this.farmerLocation,
  });

  final Land land;
  final LandService service;
  final String farmerUserId;
  final String farmerName;
  final String farmerLocation;

  @override
  State<ApplyLandScreen> createState() => _ApplyLandScreenState();
}

class _ApplyLandScreenState extends State<ApplyLandScreen> {
  final _formKey = GlobalKey<FormState>();
  final _introduction = TextEditingController();
  final _suitability = TextEditingController();
  final _experience = TextEditingController();
  final _additional = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _introduction.dispose();
    _suitability.dispose();
    _experience.dispose();
    _additional.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final application = LandApplication(
      id: 'application_${DateTime.now().microsecondsSinceEpoch}',
      landId: widget.land.id,
      ownerUserId: widget.land.ownerUserId,
      farmerUserId: widget.farmerUserId,
      farmerName: widget.farmerName,
      location: widget.farmerLocation,
      experience: _experience.text.trim(),
      skills: _suitability.text.trim(),
      message: [
        'Introduction: ${_introduction.text.trim()}',
        'Why suitable: ${_suitability.text.trim()}',
        'Experience: ${_experience.text.trim()}',
        if (_additional.text.trim().isNotEmpty)
          'Additional message: ${_additional.text.trim()}',
      ].join('\n'),
      status: LandApplication.pending,
      createdAt: DateTime.now(),
    );

    try {
      await widget.service.submitApplication(application);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Application submitted successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error is StateError
                ? error.message
                : 'Could not submit application.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
          backgroundColor: AppColors.cream,
          title: const Text('Apply for Land')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            Text(
              'Apply for ${widget.land.landName}',
              style: const TextStyle(
                color: AppColors.dark,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            _formField(
              controller: _introduction,
              label: 'Short introduction',
              hint: 'Tell the owner a little about yourself',
              validator: _required,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _formField(
              controller: _suitability,
              label: 'Why are you suitable?',
              hint: 'Share your relevant skills',
              validator: _required,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _formField(
              controller: _experience,
              label: 'Experience',
              hint: 'e.g. 5 years growing rice and wheat',
              validator: _required,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _formField(
              controller: _additional,
              label: 'Additional message',
              hint: 'Anything else you would like the owner to know',
              maxLines: 3,
              isRequired: false,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _submitting ? 'Submitting...' : 'Submit Application',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class MyLandApplicationsScreen extends StatefulWidget {
  const MyLandApplicationsScreen({
    super.key,
    required this.ownerUserId,
    this.landId,
  });
  final String ownerUserId;
  final String? landId;

  @override
  State<MyLandApplicationsScreen> createState() =>
      _MyLandApplicationsScreenState();
}

class _MyLandApplicationsScreenState extends State<MyLandApplicationsScreen> {
  final _service = LandService();
  late Future<List<({Land land, LandApplication application})>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getApplicationsForOwner(
      widget.ownerUserId,
      landId: widget.landId,
    );
  }

  Future<void> _update(String applicationId, String status) async {
    try {
      await _service.updateApplicationStatus(
        applicationId,
        status,
        ownerUserId: widget.ownerUserId,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update application: $error')),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _future = _service.getApplicationsForOwner(
        widget.ownerUserId,
        landId: widget.landId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
          backgroundColor: AppColors.cream,
          title: const Text('Applications Received')),
      body: FutureBuilder<List<({Land land, LandApplication application})>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LoadMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load applications',
              detail: snapshot.error.toString(),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const _LoadMessage(
              icon: Icons.inbox_outlined,
              title: 'No applications yet',
              detail: 'Applications for your land will appear here.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (final item in snapshot.data!)
                _ReceivedApplicationCard(
                  land: item.land,
                  application: item.application,
                  onViewProfile: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ApplicantProfileScreen(
                        application: item.application,
                      ),
                    ),
                  ),
                  onAccept: item.application.status == LandApplication.pending
                      ? () =>
                          _update(item.application.id, LandApplication.accepted)
                      : null,
                  onReject: item.application.status == LandApplication.pending
                      ? () =>
                          _update(item.application.id, LandApplication.rejected)
                      : null,
                ),
            ],
          );
        },
      ),
    );
  }
}

class MyAppliedLandsScreen extends StatefulWidget {
  const MyAppliedLandsScreen({super.key, required this.farmerUserId});
  final String farmerUserId;

  @override
  State<MyAppliedLandsScreen> createState() => _MyAppliedLandsScreenState();
}

class _MyAppliedLandsScreenState extends State<MyAppliedLandsScreen> {
  final _service = LandService();
  late Future<List<({Land land, LandApplication application})>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<({Land land, LandApplication application})>> _load() async {
    final applications =
        await _service.getApplicationsByFarmer(widget.farmerUserId);
    final lands = await _service.getLands();
    final landById = {for (final land in lands) land.id: land};
    return applications
        .where((application) => landById.containsKey(application.landId))
        .map((application) => (
              land: landById[application.landId]!,
              application: application,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
          backgroundColor: AppColors.cream,
          title: const Text('My Applied Lands')),
      body: FutureBuilder<List<({Land land, LandApplication application})>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LoadMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load your applications',
              detail: snapshot.error.toString(),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const _LoadMessage(
              icon: Icons.assignment_outlined,
              title: 'No applications yet',
              detail: 'Land applications you submit will appear here.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (final item in snapshot.data!)
                _AppliedLandCard(
                    land: item.land, application: item.application),
            ],
          );
        },
      ),
    );
  }
}

class _LandCard extends StatelessWidget {
  const _LandCard({required this.land, required this.onView});
  final Land land;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LandImage(land: land, height: 174),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  land.landName,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                _DetailLine(
                    icon: Icons.location_on_outlined, text: land.location),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                        icon: Icons.square_foot_rounded, text: _areaText(land)),
                    _InfoChip(
                        icon: Icons.grass_rounded, text: land.preferredCrop),
                    _InfoChip(
                        icon: Icons.water_drop_outlined,
                        text: land.waterSource),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  land.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child:
                      PrimaryButton(label: 'View Details', onPressed: onView),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LandImage extends StatelessWidget {
  const _LandImage({
    required this.land,
    required this.height,
    this.imageOverride,
  });
  final Land land;
  final double height;
  final String? imageOverride;

  @override
  Widget build(BuildContext context) {
    final image =
        imageOverride ?? (land.images.isEmpty ? null : land.images.first);
    if (image != null && image.startsWith('http')) {
      return Image.network(
        image,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(height),
      );
    }

    return _placeholder(height);
  }

  Widget _placeholder(double height) => Container(
        width: double.infinity,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.farmTint, AppColors.soft],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.landscape_rounded,
              color: AppColors.farmAccent, size: 54),
        ),
      );
}

class _LandGallery extends StatelessWidget {
  const _LandGallery({required this.land, required this.height});
  final Land land;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (land.images.length < 2) {
      return _LandImage(land: land, height: height);
    }
    return SizedBox(
      height: height,
      child: PageView.builder(
        itemCount: land.images.length,
        itemBuilder: (context, index) => _LandImage(
          land: land,
          height: height,
          imageOverride: land.images[index],
        ),
      ),
    );
  }
}

class _ReceivedApplicationCard extends StatelessWidget {
  const _ReceivedApplicationCard({
    required this.land,
    required this.application,
    required this.onViewProfile,
    required this.onAccept,
    required this.onReject,
  });
  final Land land;
  final LandApplication application;
  final VoidCallback onViewProfile;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
              _ApplicantAvatar(
                userId: application.farmerUserId,
                name: application.farmerName,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(land.landName,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 3),
                    Text(
                      application.farmerName,
                      style: const TextStyle(
                          color: AppColors.dark,
                          fontSize: 17,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _DetailLine(
              icon: Icons.work_outline_rounded, text: application.experience),
          if (application.skills.isNotEmpty) ...[
            const SizedBox(height: 6),
            _DetailLine(icon: Icons.stars_outlined, text: application.skills),
          ],
          if (application.location.isNotEmpty) ...[
            const SizedBox(height: 6),
            _DetailLine(
                icon: Icons.location_on_outlined, text: application.location),
          ],
          const SizedBox(height: 10),
          _DetailLine(
            icon: Icons.calendar_today_outlined,
            text: 'Applied ${_dateText(application.createdAt)}',
          ),
          const SizedBox(height: 10),
          _StatusBadge(status: application.status),
          const SizedBox(height: 12),
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
          if (onAccept != null || onReject != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Accept',
                    onPressed: () {
                      if (onAccept != null) onAccept!();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Reject',
                    outlined: true,
                    onPressed: () {
                      if (onReject != null) onReject!();
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ApplicantAvatar extends StatefulWidget {
  const _ApplicantAvatar({required this.userId, required this.name});

  final String userId;
  final String name;

  @override
  State<_ApplicantAvatar> createState() => _ApplicantAvatarState();
}

class _ApplicantAvatarState extends State<_ApplicantAvatar> {
  late final Future<Farmer?> _farmer = _load();

  Future<Farmer?> _load() async {
    final farmers = await FarmerService().getFarmers();
    for (final farmer in farmers) {
      if (farmer.userId == widget.userId) return farmer;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Farmer?>(
        future: _farmer,
        builder: (context, snapshot) {
          final image = snapshot.data?.profileImage;
          final validImage = image != null && image.startsWith('http');
          return CircleAvatar(
            backgroundColor: AppColors.farmTint,
            backgroundImage: validImage ? NetworkImage(image) : null,
            child: validImage
                ? null
                : Text(
                    widget.name.isEmpty ? 'F' : widget.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.farmAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          );
        },
      );
}

class _AppliedLandCard extends StatelessWidget {
  const _AppliedLandCard({required this.land, required this.application});
  final Land land;
  final LandApplication application;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(land.landName,
              style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          _DetailLine(icon: Icons.person_outline_rounded, text: land.ownerName),
          const SizedBox(height: 6),
          _DetailLine(icon: Icons.location_on_outlined, text: land.location),
          const SizedBox(height: 10),
          _DetailLine(
            icon: Icons.calendar_today_outlined,
            text: 'Applied ${_dateText(application.createdAt)}',
          ),
          const SizedBox(height: 10),
          _StatusBadge(status: application.status),
          if (application.status == LandApplication.accepted) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.farmTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Congratulations!\nYour application has been accepted.',
                style: TextStyle(
                  color: AppColors.dark,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == LandApplication.accepted
        ? AppColors.farmAccent
        : status == LandApplication.rejected
            ? Colors.red
            : AppColors.communityAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          ),
        ],
      );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.farmTint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.farmAccent),
            const SizedBox(width: 5),
            Text(text,
                style: const TextStyle(color: AppColors.dark, fontSize: 11.5)),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
            color: AppColors.dark, fontSize: 16, fontWeight: FontWeight.w700),
      );
}

class _LoadMessage extends StatelessWidget {
  const _LoadMessage(
      {required this.icon, required this.title, required this.detail});
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.farmAccent, size: 42),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      );
}

Widget _filter<T>({
  required String label,
  required T? value,
  required List<T> options,
  required ValueChanged<T?> onChanged,
}) {
  return Container(
    constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: DropdownButton<T>(
      value: value,
      isExpanded: true,
      underline: const SizedBox.shrink(),
      hint: Text(label, overflow: TextOverflow.ellipsis),
      items: [
        DropdownMenuItem<T>(value: null, child: Text('All $label')),
        ...options.map((option) =>
            DropdownMenuItem<T>(value: option, child: Text('$option'))),
      ],
      onChanged: onChanged,
    ),
  );
}

Widget _formField({
  required TextEditingController controller,
  required String label,
  required String hint,
  String? Function(String?)? validator,
  int maxLines = 1,
  bool isRequired = true,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          style: const TextStyle(
              color: AppColors.dark, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint),
        validator: validator ??
            (isRequired
                ? (value) => value == null || value.trim().isEmpty
                    ? 'This field is required'
                    : null
                : null),
      ),
    ],
  );
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required' : null;

String _areaText(Land land) =>
    '${land.area % 1 == 0 ? land.area.toInt() : land.area} ${land.areaUnit}';

String _dateText(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

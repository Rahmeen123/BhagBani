import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/nursery.dart';
import '../../services/nursery_service.dart';
import '../../widgets/primary_button.dart';
import 'my_nursery_screen.dart';

class NurseryApprovalScreen extends StatefulWidget {
  const NurseryApprovalScreen({super.key, required this.nursery});

  final Nursery nursery;

  @override
  State<NurseryApprovalScreen> createState() => _NurseryApprovalScreenState();
}

class _NurseryApprovalScreenState extends State<NurseryApprovalScreen> {
  final _service = NurseryService();
  late Nursery _currentNursery;
  bool _isApproving = false;

  @override
  void initState() {
    super.initState();
    _currentNursery = widget.nursery;
  }

  Future<void> _simulateAdminApproval() async {
    setState(() => _isApproving = true);
    await _service.updateNurseryStatus(_currentNursery.id, 'Approved');
    final updated = await _service.getNurseryById(_currentNursery.id);

    if (!mounted) return;
    setState(() {
      _currentNursery = updated ?? _currentNursery.copyWith(approvalStatus: 'Approved');
      _isApproving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nursery approved successfully! "My Nursery" is now unlocked.'),
        backgroundColor: AppColors.primary,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MyNurseryScreen(nursery: _currentNursery),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = _currentNursery.isApproved;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Nursery Verification'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
          children: [
            // Status Icon Container
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: isApproved ? AppColors.soft : AppColors.nurseryTint,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isApproved ? AppColors.primary : Colors.amber.shade700,
                    width: 2.5,
                  ),
                ),
                child: Icon(
                  isApproved ? Icons.verified_rounded : Icons.pending_actions_rounded,
                  color: isApproved ? AppColors.primary : Colors.amber.shade800,
                  size: 46,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              isApproved ? 'Nursery Approved!' : 'Application Under Review',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isApproved
                  ? 'Your nursery "${_currentNursery.nurseryName}" is verified. You can now manage plants and accept orders.'
                  : 'Your application for "${_currentNursery.nurseryName}" has been submitted to the Baghbani Admin for verification.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 28),

            // Step Timeline Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.025),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _timelineStep(
                    stepNumber: '1',
                    title: 'Application Submitted',
                    subtitle: 'Nursery details & location provided',
                    isDone: true,
                    isActive: false,
                  ),
                  _timelineDivider(isDone: true),
                  _timelineStep(
                    stepNumber: '2',
                    title: 'Admin Quality Review',
                    subtitle: 'Verifying plant health standards & nursery location',
                    isDone: isApproved,
                    isActive: !isApproved,
                  ),
                  _timelineDivider(isDone: isApproved),
                  _timelineStep(
                    stepNumber: '3',
                    title: 'My Nursery Activated',
                    subtitle: 'Plant catalog, inventory & pickup orders unlocked',
                    isDone: isApproved,
                    isActive: isApproved,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Application Details Summary
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Application Summary',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark),
                  ),
                  const SizedBox(height: 10),
                  _summaryRow('Nursery Name', _currentNursery.nurseryName),
                  _summaryRow('Owner', _currentNursery.ownerName),
                  _summaryRow('Location', '${_currentNursery.address}, ${_currentNursery.city}'),
                  _summaryRow('Phone', _currentNursery.phone),
                  _summaryRow('Opening Hours', _currentNursery.openingHours),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (!isApproved) ...[
              // Simulation / Demo Button
              PrimaryButton(
                label: 'Simulate Admin Approval (Demo)',
                icon: Icons.check_circle_outline,
                busy: _isApproving,
                onPressed: _isApproving ? null : _simulateAdminApproval,
              ),
              const SizedBox(height: 12),
            ] else ...[
              PrimaryButton(
                label: 'Open My Nursery Dashboard',
                icon: Icons.storefront_rounded,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => MyNurseryScreen(nursery: _currentNursery),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],

            PrimaryButton(
              label: 'Back to Profile',
              outlined: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timelineStep({
    required String stepNumber,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
  }) {
    Color circleColor = AppColors.cream;
    Color textColor = AppColors.muted;
    Color iconColor = AppColors.muted;

    if (isDone) {
      circleColor = AppColors.primary;
      textColor = AppColors.dark;
      iconColor = Colors.white;
    } else if (isActive) {
      circleColor = Colors.amber.shade700;
      textColor = AppColors.dark;
      iconColor = Colors.white;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text(
                    stepNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: iconColor,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timelineDivider({required bool isDone}) {
    return Container(
      margin: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
      width: 2,
      height: 20,
      color: isDone ? AppColors.primary : AppColors.border,
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

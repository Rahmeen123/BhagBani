import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/nursery.dart';
import '../../providers/auth_scope.dart';
import '../../services/nursery_service.dart';
import 'my_nursery_screen.dart';
import 'nursery_approval_screen.dart';
import 'register_nursery_screen.dart';

class NurseryGateScreen extends StatefulWidget {
  const NurseryGateScreen({super.key});

  @override
  State<NurseryGateScreen> createState() => _NurseryGateScreenState();
}

class _NurseryGateScreenState extends State<NurseryGateScreen> {
  final _service = NurseryService();
  bool _isLoading = true;
  Nursery? _nursery;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkNurseryStatus());
  }

  Future<void> _checkNurseryStatus() async {
    final auth = AuthScope.of(context);
    final user = auth.profile;
    final email = user?.email ?? '';

    if (email.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Please log in to manage your nursery.';
        });
      }
      return;
    }

    try {
      final nursery = await _service.getUserNursery(email);
      if (!mounted) return;

      if (nursery == null) {
        // Not registered -> go to Register Nursery
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(builder: (_) => const RegisterNurseryScreen()),
        );
      } else if (nursery.isPending) {
        // Application pending approval
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => NurseryApprovalScreen(nursery: nursery),
          ),
        );
      } else {
        // Approved nursery -> go to My Nursery Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => MyNurseryScreen(nursery: nursery),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Unable to load nursery profile: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('My Nursery'),
        backgroundColor: AppColors.cream,
        elevation: 0,
      ),
      body: Center(
        child: _isLoading
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Loading your nursery…',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.farmAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error ?? 'An unexpected error occurred.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

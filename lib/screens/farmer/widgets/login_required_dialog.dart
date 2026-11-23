import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/primary_button.dart';
import '../../auth/login_screen.dart';
import '../../auth/signup_screen.dart';

class LoginRequiredDialog extends StatelessWidget {
  const LoginRequiredDialog({
    super.key,
    required this.actionName,
    this.destination,
  });

  final String actionName;
  final WidgetBuilder? destination;

  static Future<bool> show(
    BuildContext context, {
    required String actionName,
    WidgetBuilder? destination,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => LoginRequiredDialog(
        actionName: actionName,
        destination: destination,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),

          // Lock Icon
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.soft,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
            ),
            child: const Icon(
              Icons.lock_person_rounded,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Account Required',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'You are currently exploring as a guest. Please sign in or create a Baghbani account to $actionName.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),

          PrimaryButton(
            label: 'Sign In to Continue',
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => LoginScreen(onAuthenticated: destination),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          PrimaryButton(
            label: 'Create an Account',
            outlined: true,
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => SignupScreen(onAuthenticated: destination),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

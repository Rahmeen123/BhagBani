import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Launches external Phone Dialer and WhatsApp chats without extra dependencies.
abstract final class DirectContactLauncher {
  static const _channel = MethodChannel('com.baghbani.baghbani/launcher');

  /// Optional test hook to intercept launch URIs in widget/unit tests.
  @visibleForTesting
  static Future<bool> Function(Uri uri)? testLauncher;

  static String normalizePhone(String raw) =>
      raw.replaceAll(RegExp(r'[^0-9+]'), '');

  /// Converts local Pakistani numbers (e.g. 03001234567) to international
  /// digits without leading `+` for `https://wa.me/<digits>`.
  static String formatWhatsAppDigits(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('00')) {
      return cleaned.substring(2);
    }
    if (cleaned.startsWith('0') && cleaned.length == 11) {
      return '92${cleaned.substring(1)}';
    }
    return cleaned;
  }

  static Future<void> call(
    BuildContext context,
    String phoneNumber,
  ) async {
    final normalized = normalizePhone(phoneNumber);
    if (normalized.isEmpty) {
      _showSnack(context, 'Phone number is not available.');
      return;
    }
    final uri = Uri(scheme: 'tel', path: normalized);
    final launched = await _launchUri(uri);
    if (!launched && context.mounted) {
      await Clipboard.setData(ClipboardData(text: phoneNumber));
      if (context.mounted) {
        _showSnack(context, 'Number copied: $phoneNumber');
      }
    }
  }

  static Future<void> whatsApp(
    BuildContext context,
    String whatsappOrPhone, {
    String? message,
  }) async {
    final digits = formatWhatsAppDigits(whatsappOrPhone);
    if (digits.isEmpty) {
      _showSnack(context, 'WhatsApp number is not available.');
      return;
    }
    final uri = Uri.https(
      'wa.me',
      '/$digits',
      message != null && message.trim().isNotEmpty
          ? {'text': message.trim()}
          : null,
    );
    final launched = await _launchUri(uri);
    if (!launched && context.mounted) {
      await Clipboard.setData(ClipboardData(text: whatsappOrPhone));
      if (context.mounted) {
        _showSnack(context, 'WhatsApp number copied: $whatsappOrPhone');
      }
    }
  }

  static Future<bool> _launchUri(Uri uri) async {
    final override = testLauncher;
    if (override != null) {
      return override(uri);
    }
    try {
      final result = await _channel.invokeMethod<bool>(
        'launchUri',
        {'uri': uri.toString()},
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static void _showSnack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }
}

import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.isSecondary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSecondary ? Colors.white.withValues(alpha: 0.08) : Colors.white,
          foregroundColor: isSecondary ? Colors.white70 : const Color(0xFF080808),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.2),
          disabledForegroundColor: Colors.white54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSecondary
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.transparent,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : Text(label),
      ),
    );
  }
}

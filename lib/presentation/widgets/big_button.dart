import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final Color? color;
  final IconData? icon;
  final double height;

  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.color,
    this.icon,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? (isPrimary ? AppColors.primary : Colors.white);
    final fg = (color != null || isPrimary) ? Colors.white : AppColors.primary;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: (!isPrimary && color == null)
                ? const BorderSide(color: AppColors.border, width: 1.5)
                : BorderSide.none,
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final Color? color;
  final IconData? icon;

  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? (isPrimary ? AppColors.primary : Colors.white);
    final fg = isPrimary ? Colors.white : AppColors.primary;
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isPrimary ? Colors.transparent : AppColors.border,
              width: 2,
            ),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

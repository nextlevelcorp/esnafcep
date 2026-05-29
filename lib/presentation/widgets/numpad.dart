import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppNumpad extends StatelessWidget {
  final ValueChanged<String> onTap;
  const AppNumpad({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const keys = ['1','2','3','4','5','6','7','8','9','.','0','DEL'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 2.8,
      children: keys.map((k) => _NumKey(label: k, onTap: () => onTap(k))).toList(),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NumKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: label == 'DEL'
            ? const Icon(Icons.backspace_outlined, color: AppColors.textSecondary, size: 20)
            : Text(label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )),
      ),
    );
  }
}

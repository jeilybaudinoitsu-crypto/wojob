import 'package:flutter/material.dart';
import 'package:wojob/core/theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.expand = true,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final borderRadius = BorderRadius.circular(18);
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Text(label),
      ],
    );

    final style = ElevatedButton.styleFrom(
      minimumSize: expand ? const Size.fromHeight(54) : null,
      padding: expand
          ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled
            ? AppColors.brandGradient
            : LinearGradient(
                colors: [
                  Theme.of(context).disabledColor,
                  Theme.of(context).disabledColor,
                ],
              ),
        borderRadius: borderRadius,
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : const [],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: style.copyWith(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: borderRadius),
          ),
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: child,
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.expand = true,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: expand ? const Size.fromHeight(56) : const Size(0, 56),
        side: const BorderSide(color: Colors.white, width: 1.6),
        foregroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
    );
  }
}

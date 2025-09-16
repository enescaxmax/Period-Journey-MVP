import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final child = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          )
        : Text(label);

    final style = ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      textStyle: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );

    if (icon == null) {
      return ElevatedButton(
        onPressed: effectiveOnPressed,
        style: style,
        child: child,
      );
    }

    return ElevatedButton.icon(
      onPressed: effectiveOnPressed,
      icon: icon!,
      style: style,
      label: child,
    );
  }
}

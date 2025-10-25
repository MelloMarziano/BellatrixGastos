import 'package:flutter/material.dart';

class MainNavButton extends StatelessWidget {
  const MainNavButton({
    super.key,
    required this.label,
    required this.icon,
    this.isActive = false,
    this.iconSize = 24,
    this.textStyle,
    this.activeGradient,
    this.inactiveColor,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.showLabel = false,
    this.height,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final double iconSize;
  final TextStyle? textStyle;
  final Gradient? activeGradient;
  final Color? inactiveColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;
  final bool showLabel;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final Gradient gradient =
        activeGradient ??
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6D84FF), Color(0xFF9C53FF)],
        );

    final Color inactive = inactiveColor ?? const Color(0xFF6B7280); // gray-500
    final BorderRadiusGeometry radius =
        borderRadius ?? BorderRadius.circular(24);
    final EdgeInsetsGeometry itemPadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 10);

    final Color iconColor = isActive ? Colors.white : inactive;
    final TextStyle baseLabelStyle =
        (textStyle ?? const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)).copyWith(
          color: isActive ? Colors.white : inactive,
        );

    final List<Widget> children = [
      Icon(icon, size: iconSize, color: iconColor),
    ];
    if (showLabel) {
      children.add(const SizedBox(height: 6));
      children.add(
        Text(
          label,
          style: baseLabelStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      );
    }

    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );

    final BoxDecoration decoration = isActive
        ? BoxDecoration(gradient: gradient, borderRadius: radius)
        : const BoxDecoration(color: Colors.transparent);

    return GestureDetector
    (
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: height ?? (showLabel ? 84 : 64),
        padding: itemPadding,
        alignment: Alignment.center,
        decoration: decoration,
        child: content,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../utils/constants.dart';

class NeumorphicIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? iconColor;

  const NeumorphicIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 40.0,
    this.iconColor,
  });

  @override
  State<NeumorphicIconButton> createState() => _NeumorphicIconButtonState();
}

class _NeumorphicIconButtonState extends State<NeumorphicIconButton> {
  bool _isPressed = false;

  void _handlePress(bool pressed) {
    if (widget.onPressed == null) return;
    setState(() {
      _isPressed = pressed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Base colors for the Neumorphic effect
    final shadowDark = isDarkMode 
        ? Colors.black.withValues(alpha: 0.5) 
        : Colors.black.withValues(alpha: 0.15);
    final shadowLight = isDarkMode 
        ? Colors.white.withValues(alpha: 0.05) 
        : Colors.white.withValues(alpha: 0.8);

    // Gradient colors
    final gradientColors = [
      AppColors.primary,
      AppColors.secondary,
    ];

    return GestureDetector(
      onTapDown: (_) => _handlePress(true),
      onTapUp: (_) {
        _handlePress(false);
        widget.onPressed?.call();
      },
      onTapCancel: () => _handlePress(false),
      child: Tooltip(
        message: widget.tooltip ?? '',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: _isPressed ? Alignment.bottomRight : Alignment.topLeft,
              end: _isPressed ? Alignment.topLeft : Alignment.bottomRight,
              colors: gradientColors,
            ),
            boxShadow: [
              // Convex effect (Unpressed)
              if (!_isPressed) ...[
                BoxShadow(
                  color: shadowDark,
                  offset: const Offset(4, 4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: shadowLight,
                  offset: const Offset(-4, -4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
              // Concave simulator (Pressed) - Subtle inner glow effect
              if (_isPressed) ...[
                BoxShadow(
                  color: shadowDark,
                  offset: const Offset(-2, -2),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: shadowLight,
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ],
          ),
          child: Icon(
            widget.icon,
            color: widget.iconColor ?? Colors.white,
            size: widget.size * 0.6,
          ),
        ),
      ),
    );
  }
}

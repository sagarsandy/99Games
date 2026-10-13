import 'package:flutter/material.dart';

/// An individual tile in the Number Slide grid.
class NumberSlideTile extends StatelessWidget {
  final int value;
  final bool isMovable;
  final VoidCallback? onTap;

  const NumberSlideTile({
    super.key,
    required this.value,
    required this.isMovable,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (value == 0) {
      // Empty cell slot
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    final borderColor = isMovable
        ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.6 : 0.4)
        : (isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06));

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Semantics(
      label: 'Tile $value',
      button: isMovable,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: baseBgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isMovable ? 2.0 : 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: isMovable ? 8 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isMovable ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.08),
            child: Center(
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

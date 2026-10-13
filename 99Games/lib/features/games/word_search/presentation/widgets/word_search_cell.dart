import 'package:flutter/material.dart';

/// Single cell in the Word Search grid.
class WordSearchCell extends StatelessWidget {
  final String letter;
  final bool isSelected;
  final bool isSelectionStart;
  final bool isSelectionEnd;
  final List<Color> foundColors;
  final VoidCallback? onTap;

  const WordSearchCell({
    super.key,
    required this.letter,
    this.isSelected = false,
    this.isSelectionStart = false,
    this.isSelectionEnd = false,
    this.foundColors = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine cell fill, border, and text styling
    Color backgroundColor;
    Border? border;
    Color textColor;

    if (isSelected) {
      // Active drag selection
      backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.35);
      border = Border.all(color: theme.colorScheme.primary, width: 2.0);
      textColor = theme.colorScheme.primary;
    } else if (foundColors.isNotEmpty) {
      // Found word(s)
      final primaryFoundColor = foundColors.last;
      backgroundColor = primaryFoundColor.withValues(
        alpha: isDark ? 0.32 : 0.22,
      );
      border = Border.all(
        color: primaryFoundColor.withValues(alpha: 0.8),
        width: 1.5,
      );
      textColor = isDark ? Colors.white : primaryFoundColor;
    } else {
      // Default cell
      backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;
      border = Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFE2E8F0),
        width: 1.0,
      );
      textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final fontSize = (size * 0.48).clamp(12.0, 24.0);

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(size * 0.22),
            border: border,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            letter,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }
}

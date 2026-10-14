import 'package:flutter/material.dart';
import '../../domain/number_match_models.dart';

/// An individual tile in the Number Match 9-column grid.
///
/// Distinctly renders active numbers, selected highlights, hint indicators,
/// and empty placeholders for cleared numbers.
class NumberMatchTileWidget extends StatelessWidget {
  final NumberMatchTile tile;
  final int index;
  final bool isSelected;
  final bool isHinted;
  final VoidCallback onTap;

  const NumberMatchTileWidget({
    super.key,
    required this.tile,
    required this.index,
    required this.isSelected,
    required this.isHinted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Cleared cell representation: subtle placeholder to preserve grid alignment
    if (tile.isCleared) {
      return Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    // Active cell styling
    Color backgroundColor;
    Color textColor;
    Border? border;
    List<BoxShadow>? shadows;

    if (isSelected) {
      backgroundColor = const Color(0xFF6366F1); // Indigo
      textColor = Colors.white;
      border = Border.all(color: Colors.white, width: 2.0);
      shadows = [
        BoxShadow(
          color: const Color(0xFF6366F1).withValues(alpha: 0.45),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (isHinted) {
      backgroundColor = const Color(0xFFFEF3C7); // Amber light
      textColor = const Color(0xFFB45309); // Dark amber
      border = Border.all(color: const Color(0xFFF59E0B), width: 2.5);
      shadows = [
        BoxShadow(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ];
    } else {
      backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;
      textColor = isDark ? Colors.white : const Color(0xFF0F172A);
      border = Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.12)
            : const Color(0xFFE2E8F0),
        width: 1.2,
      );
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
          blurRadius: 3,
          offset: const Offset(0, 1.5),
        ),
      ];
    }

    return Semantics(
      label: 'Number ${tile.value}, ${isSelected ? "selected" : ""}',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: border,
              boxShadow: shadows,
            ),
            child: Center(
              child: Text(
                '${tile.value}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

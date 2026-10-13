import 'package:flutter/material.dart';
import '../../domain/word_search_models.dart';
import 'word_search_palette.dart';

/// Panel displaying target words to find with found status chips.
class WordListPanel extends StatelessWidget {
  final List<String> targetWords;
  final List<FoundWord> foundWords;

  const WordListPanel({
    super.key,
    required this.targetWords,
    required this.foundWords,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final foundMap = {for (final f in foundWords) f.word.toUpperCase(): f};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.format_list_bulleted_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Words to Find',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Text(
                '${foundWords.length} / ${targetWords.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: foundWords.length == targetWords.length
                      ? const Color(0xFF10B981)
                      : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: targetWords.map((word) {
              final isFound = foundMap.containsKey(word.toUpperCase());
              final foundInfo = foundMap[word.toUpperCase()];
              final color = isFound && foundInfo != null
                  ? WordSearchPalette.getColor(foundInfo.colorIndex)
                  : null;

              return _buildWordChip(
                word: word,
                isFound: isFound,
                accentColor: color,
                isDark: isDark,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWordChip({
    required String word,
    required bool isFound,
    required Color? accentColor,
    required bool isDark,
  }) {
    if (isFound && accentColor != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 14, color: accentColor),
            const SizedBox(width: 5),
            Text(
              word,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : accentColor,
                decoration: TextDecoration.lineThrough,
                decorationColor: accentColor,
                decorationThickness: 2.0,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF334155).withValues(alpha: 0.4)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFCBD5E1),
          width: 1.0,
        ),
      ),
      child: Text(
        word,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white70 : const Color(0xFF1E293B),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

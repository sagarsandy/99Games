import 'package:flutter/material.dart';

/// Curated harmonious colors for highlighting found words and their matching chips.
abstract final class WordSearchPalette {
  static const List<Color> colors = [
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
    Color(0xFF14B8A6), // Teal
    Color(0xFF6366F1), // Indigo
    Color(0xFF84CC16), // Lime
    Color(0xFFE11D48), // Rose
    Color(0xFF0284C7), // Sky
    Color(0xFFA855F7), // Violet
    Color(0xFFD97706), // Warm Amber
    Color(0xFF059669), // Mint
  ];

  static Color getColor(int index) => colors[index % colors.length];
}

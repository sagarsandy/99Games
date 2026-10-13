import 'package:flutter/material.dart';
import '../../cubit/home_state.dart';

/// Horizontal filter bar for filtering games by category.
class CategoryFilterBar extends StatelessWidget {
  final GameCategory selectedCategory;
  final ValueChanged<GameCategory> onSelectCategory;

  const CategoryFilterBar({
    super.key,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBgColor = isDark
        ? const Color(0xFF334155) // Slate-700
        : const Color(0xFF64748B); // Slate-500

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: GameCategory.values.map((category) {
          final isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                category.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: const Color(0xFF4F46E5),
              backgroundColor: unselectedBgColor,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (_) => onSelectCategory(category),
            ),
          );
        }).toList(),
      ),
    );
  }
}

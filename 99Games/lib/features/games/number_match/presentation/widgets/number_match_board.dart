import 'package:flutter/material.dart';
import '../../cubit/number_match_cubit.dart';
import '../../cubit/number_match_state.dart';
import '../../domain/number_match_engine.dart';
import 'number_match_tile.dart';

/// The responsive 9-column Number Match grid board.
class NumberMatchBoard extends StatelessWidget {
  final NumberMatchState state;
  final NumberMatchCubit cubit;

  const NumberMatchBoard({super.key, required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tiles = state.tiles;
    final selectedIdx = state.selectedIndex;
    final hint = state.hintPair;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tiles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: NumberMatchEngine.columns,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final tile = tiles[index];
            final isSelected = selectedIdx == index;
            final isHinted =
                hint != null &&
                (hint.firstIndex == index || hint.secondIndex == index);

            return NumberMatchTileWidget(
              key: ValueKey('tile_${tile.id}'),
              tile: tile,
              index: index,
              isSelected: isSelected,
              isHinted: isHinted,
              onTap: () => cubit.selectTile(index),
            );
          },
        ),
      ),
    );
  }
}

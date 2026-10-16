import 'package:flutter/material.dart';
import '../../domain/fish_family_models.dart';
import '../painters/fish_painter.dart';
import '../painters/fish_tank_painter.dart';

/// Interactive widget representing an aquarium tank and its stacked fish.
class FishTankWidget extends StatelessWidget {
  final FishTank tank;
  final bool isSelected;
  final bool isShaking;
  final String? hiddenFishId;
  final VoidCallback onTap;

  const FishTankWidget({
    super.key,
    required this.tank,
    required this.isSelected,
    this.isShaking = false,
    this.hiddenFishId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tankHeight = 32.0 + (tank.capacity * 45.0);
    final visibleFishCount = hiddenFishId == null
        ? tank.fish.length
        : tank.fish.where((f) => f.id != hiddenFishId).length;

    return AnimatedSlide(
      offset: Offset(isShaking ? 0.04 : 0.0, 0),
      duration: const Duration(milliseconds: 120),
      curve: Curves.elasticIn,
      child: Semantics(
        button: true,
        label:
            'Tank ${tank.id + 1}, contains $visibleFishCount of ${tank.capacity} fish',
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: CustomPaint(
            painter: FishTankPainter(
              capacity: tank.capacity,
              fishCount: visibleFishCount,
              isSelected: isSelected,
              isCompleted: tank.isComplete,
              isDark: isDark,
              waterAnimation: 0.0,
            ),
            child: SizedBox(
              width: 74,
              height: tankHeight,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  // Stacked fish slots from bottom to top
                  ...List.generate(tank.capacity, (slotIndex) {
                    final fishY = 14.0 + (slotIndex * 45.0);
                    final hasFish = slotIndex < tank.fish.length;

                    if (!hasFish) {
                      return const SizedBox.shrink();
                    }

                    final fish = tank.fish[slotIndex];
                    if (hiddenFishId != null && fish.id == hiddenFishId) {
                      return const SizedBox.shrink();
                    }
                    final isTop = slotIndex == tank.fish.length - 1;
                    final isThisSelected = isSelected && isTop;

                    final species = FishSpecies.getById(fish.speciesId);
                    final selectedLift = isThisSelected ? 16.0 : 0.0;

                    return AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      bottom: fishY + selectedLift,
                      child: SizedBox(
                        width: 64,
                        height: 40,
                        child: CustomPaint(
                          painter: FishPainter(
                            species: species,
                            expression: isThisSelected
                                ? FishExpression.cute
                                : fish.expression,
                            isSelected: isThisSelected,
                            animationProgress: 0.0,
                            facingRight: (slotIndex % 2 == 0),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

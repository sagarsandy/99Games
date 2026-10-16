import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../cubit/word_circle_cubit.dart';
import '../../cubit/word_circle_state.dart';
import '../painters/word_circle_path_painter.dart';

/// Interactive circular letter wheel supporting drag-to-connect gestures,
/// dynamic path drawing, and responsive scaling across phone and tablet screens.
class WordCircleWheel extends StatelessWidget {
  final WordCircleState state;
  final WordCircleCubit cubit;

  const WordCircleWheel({super.key, required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Size wheel dynamically to available space while keeping it circular
        final maxSize = math.min(
          constraints.maxWidth,
          constraints.maxHeight > 0 ? constraints.maxHeight : 280.0,
        );
        final wheelSize = maxSize.clamp(200.0, 290.0);
        final tileRadius = wheelSize < 240 ? 22.0 : 26.0;
        final center = Offset(wheelSize / 2, wheelSize / 2);
        final radius = (wheelSize / 2) - tileRadius - 8.0;

        final letters = state.wheelLetters;
        final totalLetters = letters.length;

        // Calculate polar coordinates for each letter around the wheel circle
        final letterOffsets = <Offset>[];
        for (int i = 0; i < totalLetters; i++) {
          final angle = (-math.pi / 2) + (2 * math.pi * i / totalLetters);
          final x = center.dx + (radius * math.cos(angle));
          final y = center.dy + (radius * math.sin(angle));
          letterOffsets.add(Offset(x, y));
        }

        // Map selected letter IDs to their current wheel indices
        final selectedIndices = <int>[];
        for (final id in state.selectedLetterIds) {
          final idx = letters.indexWhere((l) => l.id == id);
          if (idx != -1) selectedIndices.add(idx);
        }

        int? hitTestLetter(Offset localPos) {
          final hitDist = tileRadius + 14.0;
          for (int i = 0; i < letterOffsets.length; i++) {
            final dist = (letterOffsets[i] - localPos).distance;
            if (dist <= hitDist) {
              return letters[i].id;
            }
          }
          return null;
        }

        return Center(
          child: SizedBox(
            width: wheelSize,
            height: wheelSize,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) {
                final hitId = hitTestLetter(details.localPosition);
                if (hitId != null) {
                  cubit.startDrag(hitId, pointerPos: details.localPosition);
                }
              },
              onPanUpdate: (details) {
                final hitId = hitTestLetter(details.localPosition);
                if (hitId != null) {
                  cubit.addLetterToDrag(
                    hitId,
                    pointerPos: details.localPosition,
                  );
                } else {
                  cubit.updatePointer(details.localPosition);
                }
              },
              onPanEnd: (_) => cubit.endDrag(),
              onPanCancel: () => cubit.clearSelection(),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Wheel background and connecting path
                  Positioned.fill(
                    child: CustomPaint(
                      painter: WordCirclePathPainter(
                        letterPositions: letterOffsets,
                        selectedIndices: selectedIndices,
                        pointerPosition: state.pointerPosition,
                        pathColor: const Color(0xFF06B6D4),
                        wheelBorderColor: const Color(0xFF0891B2),
                        isDark: isDark,
                      ),
                    ),
                  ),

                  // 2. Letter tiles arranged in a circle
                  ...List.generate(totalLetters, (i) {
                    final wl = letters[i];
                    final pos = letterOffsets[i];
                    final isSelected = state.selectedLetterIds.contains(wl.id);

                    return Positioned(
                      left: pos.dx - tileRadius,
                      top: pos.dy - tileRadius,
                      width: tileRadius * 2,
                      height: tileRadius * 2,
                      child: Semantics(
                        button: true,
                        label: 'Letter ${wl.letter}',
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? const Color(0xFF06B6D4)
                                : (isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.white),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                        ? const Color(
                                            0xFF38BDF8,
                                          ).withValues(alpha: 0.3)
                                        : const Color(
                                            0xFF0284C7,
                                          ).withValues(alpha: 0.25)),
                              width: isSelected ? 2.5 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? const Color(
                                        0xFF06B6D4,
                                      ).withValues(alpha: 0.5)
                                    : Colors.black.withValues(
                                        alpha: isDark ? 0.35 : 0.08,
                                      ),
                                blurRadius: isSelected ? 10.0 : 4.0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              wl.letter,
                              style: TextStyle(
                                fontSize: tileRadius * 0.95,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import '../../cubit/worm_escape_cubit.dart';
import '../../cubit/worm_escape_state.dart';
import '../../domain/worm_escape_models.dart';
import '../painters/worm_escape_board_painter.dart';

/// Interactive board widget managing animation controllers and rendering the custom-painted board.
class WormEscapeBoard extends StatefulWidget {
  final WormEscapeState state;
  final WormEscapeCubit cubit;

  const WormEscapeBoard({super.key, required this.state, required this.cubit});

  @override
  State<WormEscapeBoard> createState() => _WormEscapeBoardState();
}

class _WormEscapeBoardState extends State<WormEscapeBoard>
    with TickerProviderStateMixin {
  late final AnimationController _escapeController;
  late final CurvedAnimation _escapeAnimation;

  late final AnimationController _shakeController;
  late final CurvedAnimation _shakeAnimation;

  late final AnimationController _hintController;

  String? _currentlyAnimatingWormId;

  @override
  void initState() {
    super.initState();

    _escapeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _escapeAnimation = CurvedAnimation(
      parent: _escapeController,
      curve: Curves.easeInOutCubic,
    );

    _escapeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final wormId = _currentlyAnimatingWormId;
        _currentlyAnimatingWormId = null;
        _escapeController.reset();
        if (wormId != null) {
          widget.cubit.onEscapeAnimationCompleted(wormId);
        }
      }
    });

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _shakeAnimation = CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    );

    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
        widget.cubit.onBlockedAnimationCompleted();
      }
    });

    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    if (widget.state.hintWormId != null) {
      _hintController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant WormEscapeBoard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Escape animation trigger
    if (widget.state.animatingWormId != null &&
        widget.state.animatingWormId != _currentlyAnimatingWormId) {
      _currentlyAnimatingWormId = widget.state.animatingWormId;
      _escapeController.forward(from: 0.0);
    }

    // Shake animation trigger
    if (widget.state.blockedWormId != null &&
        widget.state.blockedWormId != oldWidget.state.blockedWormId) {
      _shakeController.forward(from: 0.0);
    }

    // Hint animation trigger
    if (widget.state.hintWormId != oldWidget.state.hintWormId) {
      if (widget.state.hintWormId != null) {
        _hintController.repeat(reverse: true);
      } else {
        _hintController.stop();
        _hintController.reset();
      }
    }
  }

  @override
  void dispose() {
    _escapeController.dispose();
    _shakeController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  GridPosition? _offsetToCoord(
    Offset localPosition,
    double cellSize,
    int boardSize,
  ) {
    final col = (localPosition.dx / cellSize).floor();
    final row = (localPosition.dy / cellSize).floor();

    if (row >= 0 && row < boardSize && col >= 0 && col < boardSize) {
      return GridPosition(row, col);
    }
    return null;
  }

  void _handleTap(Offset localPosition, double cellSize, int boardSize) {
    final coord = _offsetToCoord(localPosition, cellSize, boardSize);
    if (coord != null) {
      widget.cubit.tapWormAtCell(coord);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boardSize = widget.state.engine.boardSize;

    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardPixelSize = min(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            final cellSize = boardPixelSize / boardSize;

            return IgnorePointer(
              ignoring: widget.state.isWon,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  _handleTap(details.localPosition, cellSize, boardSize);
                },
                child: Container(
                  width: boardPixelSize,
                  height: boardPixelSize,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.state.isWon
                          ? const Color(0xFF10B981)
                          : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0)),
                      width: widget.state.isWon ? 2.5 : 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.state.isWon
                            ? const Color(0xFF10B981).withValues(alpha: 0.25)
                            : Colors.black.withValues(
                                alpha: isDark ? 0.35 : 0.08,
                              ),
                        blurRadius: widget.state.isWon ? 20 : 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _escapeAnimation,
                        _shakeAnimation,
                        _hintController,
                      ]),
                      builder: (context, _) {
                        return CustomPaint(
                          painter: WormEscapeBoardPainter(
                            engine: widget.state.engine,
                            isDark: isDark,
                            animatingWormId: _currentlyAnimatingWormId,
                            escapeProgress: _escapeAnimation.value,
                            blockedWormId: widget.state.blockedWormId,
                            blockingWormId: widget.state.blockingWormId,
                            blockedProgress: _shakeAnimation.value,
                            hintWormId: widget.state.hintWormId,
                            hintPulse: _hintController.value,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

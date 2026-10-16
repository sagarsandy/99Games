import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/fruit_catcher_cubit.dart';
import '../cubit/fruit_catcher_state.dart';
import '../domain/fruit_catcher_models.dart';
import 'painters/basket_painter.dart';
import 'painters/catch_effects_painter.dart';
import 'painters/catcher_background_painter.dart';
import 'painters/fruit_item_painter.dart';
import 'widgets/fruit_catcher_game_over_dialog.dart';
import 'widgets/fruit_catcher_hud.dart';
import 'widgets/fruit_catcher_start_overlay.dart';

/// Main gameplay screen for Game 13: Fruit Catcher.
class FruitCatcherScreen extends StatefulWidget {
  const FruitCatcherScreen({super.key});

  @override
  State<FruitCatcherScreen> createState() => _FruitCatcherScreenState();
}

class _FruitCatcherScreenState extends State<FruitCatcherScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    final cubit = context.read<FruitCatcherCubit>();
    if (cubit.state.status != GameStatus.playing) {
      if (_ticker.isActive) {
        _ticker.stop();
      }
      return;
    }

    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    // Clamp dt to avoid huge jumps on frame drops
    final clampedDt = dt.clamp(0.0, 0.05);
    cubit.updateGame(clampedDt);
  }

  void _startTicker() {
    _lastElapsed = Duration.zero;
    if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void _stopTicker() {
    if (_ticker.isActive) {
      _ticker.stop();
    }
    _lastElapsed = Duration.zero;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<FruitCatcherCubit, FruitCatcherState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == GameStatus.playing) {
          _startTicker();
        } else {
          _stopTicker();
        }
      },
      builder: (context, state) {
        final cubit = context.read<FruitCatcherCubit>();

        // Subtle screen shake when damaged by bomb
        final shakeOffset = state.isDamaged
            ? const Offset(6.0, 0.0)
            : Offset.zero;

        return Scaffold(
          body: Transform.translate(
            offset: shakeOffset,
            child: Stack(
              children: [
                // 1. Cheerful arcade background painter
                Positioned.fill(
                  child: CustomPaint(
                    painter: CatcherBackgroundPainter(isDark: isDark),
                  ),
                ),

                // 2. Play Area (Gestures, Falling items, Basket, Catch effects)
                SafeArea(
                  child: Column(
                    children: [
                      // Top HUD
                      FruitCatcherHud(state: state),

                      // Interactive Game Canvas
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final playWidth = constraints.maxWidth;
                            final playHeight = constraints.maxHeight;

                            return GestureDetector(
                              key: const Key('fruit_catcher_play_area_gesture'),
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (details) {
                                if (state.status == GameStatus.playing) {
                                  final normX =
                                      details.localPosition.dx / playWidth;
                                  cubit.moveBasket(normX);
                                }
                              },
                              onPanUpdate: (details) {
                                if (state.status == GameStatus.playing) {
                                  final normX =
                                      details.localPosition.dx / playWidth;
                                  cubit.moveBasket(normX);
                                }
                              },
                              onTapDown: (details) {
                                if (state.status != GameStatus.playing) return;
                                final tapX =
                                    details.localPosition.dx / playWidth;
                                if (tapX < 0.40) {
                                  cubit.nudgeBasket(-0.08);
                                } else if (tapX > 0.60) {
                                  cubit.nudgeBasket(0.08);
                                } else {
                                  cubit.moveBasket(tapX);
                                }
                              },
                              child: Stack(
                                children: [
                                  // Falling Items (Fruits & Bombs)
                                  for (final item in state.items)
                                    _buildFallingItem(
                                      item,
                                      playWidth,
                                      playHeight,
                                    ),

                                  // Basket
                                  _buildBasket(
                                    state.basket,
                                    playWidth,
                                    playHeight,
                                    isDark,
                                  ),

                                  // Catch Effects, Floating Indicators & Damage Flash
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: CustomPaint(
                                        painter: CatchEffectsPainter(
                                          particles: state.particles,
                                          indicators: state.indicators,
                                          isDamaged: state.isDamaged,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Directional touch helper arrows (subtle, transparent)
                                  if (state.status == GameStatus.playing)
                                    Positioned(
                                      bottom: 12,
                                      left: 12,
                                      child: IgnorePointer(
                                        child: Icon(
                                          Icons.chevron_left_rounded,
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.25,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.18,
                                                ),
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                  if (state.status == GameStatus.playing)
                                    Positioned(
                                      bottom: 12,
                                      right: 12,
                                      child: IgnorePointer(
                                        child: Icon(
                                          Icons.chevron_right_rounded,
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.25,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.18,
                                                ),
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Start Screen Overlay
                if (state.status == GameStatus.ready)
                  FruitCatcherStartOverlay(
                    state: state,
                    onStart: () {
                      cubit.startGame();
                      _startTicker();
                    },
                  ),

                // 4. Game Over Overlay
                if (state.status == GameStatus.gameOver)
                  FruitCatcherGameOverDialog(
                    state: state,
                    cubit: cubit,
                    onPlayAgain: () {
                      cubit.playAgain();
                      _startTicker();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallingItem(
    FallingItem item,
    double playWidth,
    double playHeight,
  ) {
    // Radius in pixels based on item radius
    final radius = item.radius * playWidth;
    final itemPx = item.x * playWidth;
    final itemPy = item.y * playHeight;

    return Positioned(
      key: ValueKey('falling_item_${item.id}'),
      left: itemPx - radius,
      top: itemPy - radius,
      width: radius * 2,
      height: radius * 2,
      child: IgnorePointer(
        child: CustomPaint(
          painter: FruitItemPainter(
            type: item.type,
            radius: radius,
            rotation: item.rotation,
          ),
        ),
      ),
    );
  }

  Widget _buildBasket(
    BasketModel basket,
    double playWidth,
    double playHeight,
    bool isDark,
  ) {
    final basketW = basket.width * playWidth;
    final basketH = basket.height * playHeight;
    final basketLeft = basket.x * playWidth - basketW / 2;
    final basketTop = basket.y * playHeight - basketH / 2;

    return Positioned(
      key: const Key('fruit_catcher_basket'),
      left: basketLeft,
      top: basketTop,
      width: basketW,
      height: basketH,
      child: IgnorePointer(
        child: CustomPaint(painter: BasketPainter(isDark: isDark)),
      ),
    );
  }
}

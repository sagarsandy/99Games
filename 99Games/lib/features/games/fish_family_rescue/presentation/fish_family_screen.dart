import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/fish_family_cubit.dart';
import '../cubit/fish_family_state.dart';
import '../domain/fish_family_models.dart';
import 'painters/aquarium_effects_painter.dart';
import 'widgets/animated_swimming_fish.dart';
import 'widgets/fish_family_controls.dart';
import 'widgets/fish_family_level_header.dart';
import 'widgets/fish_family_results_dialog.dart';
import 'widgets/fish_tank_row.dart';

/// Main screen for Game 11: Fish Family Rescue with visible swimming animations.
class FishFamilyScreen extends StatefulWidget {
  final bool enableAmbientAnimation;

  const FishFamilyScreen({super.key, this.enableAmbientAnimation = true});

  @override
  State<FishFamilyScreen> createState() => _FishFamilyScreenState();
}

class _FishFamilyScreenState extends State<FishFamilyScreen>
    with TickerProviderStateMixin {
  final GlobalKey _boardKey = GlobalKey();
  final Map<int, GlobalKey> _tankKeys = {};

  late AnimationController _ambientController;
  late AnimationController _moveController;
  late CurvedAnimation _curvedMoveAnimation;

  FishTrajectory? _activeTrajectory;
  PendingFishMove? _activeMove;
  int? _activeSequence;
  bool _isViewingBoard = false;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (widget.enableAmbientAnimation && !isTest) {
      _ambientController.repeat();
    }

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _curvedMoveAnimation = CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeInOutCubic,
    );

    _moveController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onMoveAnimationComplete();
      }
    });
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _curvedMoveAnimation.dispose();
    _moveController.dispose();
    super.dispose();
  }

  void _onMoveAnimationComplete() {
    if (!mounted) return;
    final seq = _activeSequence;
    setState(() {
      _activeSequence = null;
      _activeTrajectory = null;
      _activeMove = null;
    });
    if (seq != null) {
      context.read<FishFamilyCubit>().completePendingMove(seq);
    }
  }

  void _cancelMoveAnimation() {
    _moveController.stop();
    setState(() {
      _activeSequence = null;
      _activeTrajectory = null;
      _activeMove = null;
    });
  }

  void _startMoveAnimation(PendingFishMove move, FishFamilyState state) {
    final boardBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    final fromBox =
        _tankKeys[move.fromTankId]?.currentContext?.findRenderObject()
            as RenderBox?;
    final toBox =
        _tankKeys[move.toTankId]?.currentContext?.findRenderObject()
            as RenderBox?;

    // If render layout isn't established (e.g. headless tests), safely finalize immediately
    if (boardBox == null ||
        fromBox == null ||
        toBox == null ||
        !fromBox.hasSize ||
        !toBox.hasSize ||
        !boardBox.hasSize) {
      context.read<FishFamilyCubit>().completePendingMove(move.sequence);
      return;
    }

    final fromTank = state.tanks.firstWhere((t) => t.id == move.fromTankId);
    final toTank = state.tanks.firstWhere((t) => t.id == move.toTankId);

    final fromOffset = fromBox.localToGlobal(Offset.zero, ancestor: boardBox);
    final toOffset = toBox.localToGlobal(Offset.zero, ancestor: boardBox);

    final fromX = fromOffset.dx + (fromBox.size.width / 2.0);
    final toX = toOffset.dx + (toBox.size.width / 2.0);

    // Source fish was at top slot and visually lifted by 16.0 px
    final fromSlotIndex = math.max(0, fromTank.fish.length - 1);
    final fromFishY = 14.0 + (fromSlotIndex * 45.0);
    final fromY =
        fromOffset.dy + fromBox.size.height - (fromFishY + 16.0) - 20.0;

    // Destination fish will settle at slot index toTank.fish.length (lift 0.0)
    final toSlotIndex = toTank.fish.length;
    final toFishY = 14.0 + (toSlotIndex * 45.0);
    final toY = toOffset.dy + toBox.size.height - toFishY - 20.0;

    final startCenter = Offset(fromX, fromY);
    final endCenter = Offset(toX, toY);

    final trajectory = FishTrajectory.calculate(
      start: startCenter,
      end: endCenter,
      minBoardY: 12.0,
    );

    final durationMs = (360 + (trajectory.distance * 0.45))
        .clamp(360, 540)
        .round();

    setState(() {
      _activeSequence = move.sequence;
      _activeMove = move;
      _activeTrajectory = trajectory;
    });

    _moveController.duration = Duration(milliseconds: durationMs);
    _moveController.forward(from: 0.0);
  }

  void _showResults(BuildContext context, FishFamilyState state) {
    final cubit = context.read<FishFamilyCubit>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => FishFamilyResultsDialog(
        state: state,
        cubit: cubit,
        onViewBoard: () {
          setState(() {
            _isViewingBoard = true;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColors = isDark
        ? [const Color(0xFF091E3A), const Color(0xFF0F172A)]
        : [const Color(0xFFE0F2FE), const Color(0xFFF0FDF4)];

    return BlocConsumer<FishFamilyCubit, FishFamilyState>(
      listener: (context, state) {
        if (!state.isWon && _isViewingBoard) {
          setState(() {
            _isViewingBoard = false;
          });
        }

        // Trigger or synchronize swimming animation
        if (state.pendingMove != null &&
            _activeSequence != state.pendingMove!.sequence) {
          _startMoveAnimation(state.pendingMove!, state);
        } else if (state.pendingMove == null && _activeSequence != null) {
          _cancelMoveAnimation();
        }

        if (state.isWon &&
            !state.hasShownWinDialog &&
            !_isViewingBoard &&
            !state.isAnimating) {
          context.read<FishFamilyCubit>().markWinDialogShown();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showResults(context, state);
            }
          });
        }
      },
      builder: (context, state) {
        final cubit = context.read<FishFamilyCubit>();

        for (final tank in state.tanks) {
          _tankKeys.putIfAbsent(tank.id, () => GlobalKey());
        }

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: bgColors,
              ),
            ),
            child: SafeArea(
              child: Stack(
                key: _boardKey,
                children: [
                  // 1. Ambient rising bubbles and caustic light rays
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _ambientController,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: AquariumEffectsPainter(
                            progress: _ambientController.value,
                            isDark: isDark,
                          ),
                        );
                      },
                    ),
                  ),

                  // 2. Main UI Layout
                  Column(
                    children: [
                      FishFamilyLevelHeader(state: state, cubit: cubit),
                      Expanded(
                        child: state.isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF06B6D4),
                                ),
                              )
                            : FishTankRow(
                                state: state,
                                cubit: cubit,
                                tankKeys: _tankKeys,
                              ),
                      ),
                      FishFamilyControls(
                        state: state,
                        cubit: cubit,
                        onViewResults: (_isViewingBoard && state.isWon)
                            ? () {
                                setState(() {
                                  _isViewingBoard = false;
                                });
                                _showResults(context, state);
                              }
                            : null,
                      ),
                    ],
                  ),

                  // 3. Moving fish animated layer (rendered above tanks and glass)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _curvedMoveAnimation,
                        builder: (context, _) {
                          if (_activeTrajectory == null ||
                              _activeMove == null) {
                            return const SizedBox.shrink();
                          }
                          return Stack(
                            children: [
                              AnimatedSwimmingFishOverlay(
                                animation: _curvedMoveAnimation,
                                trajectory: _activeTrajectory!,
                                fish: _activeMove!.fish,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

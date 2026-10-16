import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/reaction_test_cubit.dart';
import '../cubit/reaction_test_state.dart';
import '../domain/reaction_test_engine.dart';
import '../domain/reaction_test_models.dart';
import 'widgets/reaction_test_controls.dart';
import 'widgets/reaction_test_play_area.dart';
import 'widgets/reaction_test_results.dart';
import 'widgets/reaction_test_round_indicator.dart';

/// Main screen for the Reaction Test game with lifecycle awareness and responsive layout.
class ReactionTestScreen extends StatefulWidget {
  const ReactionTestScreen({super.key});

  @override
  State<ReactionTestScreen> createState() => _ReactionTestScreenState();
}

class _ReactionTestScreenState extends State<ReactionTestScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      context.read<ReactionTestCubit>().handleAppPaused();
    }
  }

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.help_outline_rounded, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('How to Play'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRuleItem(
                  '1. Wait for Green',
                  'When a round starts, the screen is RED. Wait patiently. Tapping while red triggers a False Start.',
                ),
                _buildRuleItem(
                  '2. Tap as Fast as You Can',
                  'Between 2 and 5 seconds later, the screen will flash GREEN. Tap anywhere inside the play area immediately!',
                ),
                _buildRuleItem(
                  '3. Complete 5 Rounds',
                  'The challenge consists of 5 rounds. Your reaction times, average reflex speed, fastest round, and personal best will be calculated.',
                ),
                _buildRuleItem(
                  '4. Reflex Benchmarks',
                  '• Under 200 ms: Very fast\n• 200–250 ms: Fast\n• 251–350 ms: Typical range\n• Above 350 ms: Keep practicing',
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Got it!'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRuleItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(description, style: const TextStyle(fontSize: 13, height: 1.3)),
        ],
      ),
    );
  }

  void _confirmRestart(BuildContext context, ReactionTestCubit cubit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restart Challenge?'),
        content: const Text(
          'Your current progress in this 5-round challenge will be reset.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              cubit.startGame();
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<ReactionTestCubit>();

    return BlocBuilder<ReactionTestCubit, ReactionTestState>(
      builder: (context, state) {
        final bool inGame =
            state.phase != ReactionPhase.intro &&
            state.phase != ReactionPhase.completed;

        return SelectionContainer.disabled(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Reaction Test'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back to Home',
                onPressed: () {
                  if (inGame) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Text('Leave Challenge?'),
                        content: const Text(
                          'Your current round progress will be lost.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Stay'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              context.go('/');
                            },
                            child: const Text('Leave'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    context.go('/');
                  }
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline_rounded),
                  tooltip: 'How to Play',
                  onPressed: () => _showRulesDialog(context),
                ),
                if (inGame)
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Restart',
                    onPressed: () => _confirmRestart(context, cubit),
                  ),
              ],
            ),
            body: SafeArea(child: _buildBody(context, state, cubit, theme)),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ReactionTestState state,
    ReactionTestCubit cubit,
    ThemeData theme,
  ) {
    switch (state.phase) {
      case ReactionPhase.intro:
        return _buildIntroView(context, state, cubit, theme);

      case ReactionPhase.completed:
        return ReactionTestResults(state: state, cubit: cubit);

      case ReactionPhase.waiting:
      case ReactionPhase.green:
      case ReactionPhase.falseStart:
      case ReactionPhase.roundResult:
        return Column(
          children: [
            ReactionTestRoundIndicator(state: state),
            ReactionTestPlayArea(state: state, cubit: cubit),
            ReactionTestControls(state: state, cubit: cubit),
          ],
        );
    }
  }

  Widget _buildIntroView(
    BuildContext context,
    ReactionTestState state,
    ReactionTestCubit cubit,
    ThemeData theme,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Reflex Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.speed_rounded,
                    size: 80,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'Reaction Test',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Wait for green, then tap as quickly as possible.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Challenge Info Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    _buildFeatureRow(
                      Icons.repeat_rounded,
                      '5-Round Challenge',
                      'Calculates average, fastest, and slowest reaction times.',
                      theme,
                    ),
                    const Divider(height: 20),
                    _buildFeatureRow(
                      Icons.warning_amber_rounded,
                      'Watch for False Starts',
                      'Tapping while the screen is red counts as a false start.',
                      theme,
                    ),
                    const Divider(height: 20),
                    _buildFeatureRow(
                      Icons.timer_rounded,
                      'Precision Timing',
                      'Accurate millisecond measurements on every tap.',
                      theme,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Personal Best Pill
              if (state.stats.bestSingleMs != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFFD97706),
                        size: 20,
                      ),
                      Text(
                        'Personal Best: ${ReactionTestEngine.formatMs(state.stats.bestSingleMs)}',
                        style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (state.stats.bestSessionAverageMs != null)
                        Text(
                          '• Avg: ${ReactionTestEngine.formatAverage(state.stats.bestSessionAverageMs)}',
                          style: const TextStyle(
                            color: Color(0xFFB45309),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Start Game Button
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: cubit.startGame,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                  label: const Text(
                    'Start Game',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    IconData icon,
    String title,
    String subtitle,
    ThemeData theme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

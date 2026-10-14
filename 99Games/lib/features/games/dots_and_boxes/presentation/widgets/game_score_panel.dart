import 'package:flutter/material.dart';
import '../../cubit/dots_and_boxes_state.dart';
import '../../domain/dots_and_boxes_models.dart';

/// Presentation panel displaying current scores, active turn indicator,
/// claimed boxes progress, and historical stats.
class GameScorePanel extends StatelessWidget {
  final DotsAndBoxesState state;

  const GameScorePanel({super.key, required this.state});

  static const Color p1Color = Color(0xFF2563EB); // Electric Blue
  static const Color p2Color = Color(0xFFE11D48); // Radiant Rose

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final p1Name =
        state.currentPlayer == DotsPlayer.player1 && !state.isGameOver
        ? '${state.currentPlayer.displayName(state.gameMode)} (Turn)'
        : DotsPlayer.player1.displayName(state.gameMode);

    final p2Name =
        state.currentPlayer == DotsPlayer.player2 && !state.isGameOver
        ? state.isAiThinking
              ? 'Computer (Thinking...)'
              : '${DotsPlayer.player2.displayName(state.gameMode)} (Turn)'
        : DotsPlayer.player2.displayName(state.gameMode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Player Cards and Scores
          Row(
            children: [
              // Player 1 Card
              Expanded(
                child: _buildPlayerCard(
                  context: context,
                  player: DotsPlayer.player1,
                  displayName: p1Name,
                  score: state.player1Score,
                  color: p1Color,
                  isActiveTurn:
                      state.currentPlayer == DotsPlayer.player1 &&
                      !state.isGameOver,
                  icon: state.gameMode == DotsGameMode.vsAi
                      ? Icons.person_rounded
                      : Icons.looks_one_rounded,
                ),
              ),

              const SizedBox(width: 12),

              // VS / Remaining Boxes Divider
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.remainingBoxes} left',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // Player 2 Card
              Expanded(
                child: _buildPlayerCard(
                  context: context,
                  player: DotsPlayer.player2,
                  displayName: p2Name,
                  score: state.player2Score,
                  color: p2Color,
                  isActiveTurn:
                      state.currentPlayer == DotsPlayer.player2 &&
                      !state.isGameOver,
                  icon: state.gameMode == DotsGameMode.vsAi
                      ? Icons.smart_toy_rounded
                      : Icons.looks_two_rounded,
                  isAiThinking: state.isAiThinking,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Row 2: Progress indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  if (state.player1Score > 0)
                    Expanded(
                      flex: state.player1Score,
                      child: Container(color: p1Color),
                    ),
                  if (state.player2Score > 0)
                    Expanded(
                      flex: state.player2Score,
                      child: Container(color: p2Color),
                    ),
                  if (state.remainingBoxes > 0)
                    Expanded(
                      flex: state.remainingBoxes,
                      child: Container(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Row 3: Stats summary
          if (state.stats.totalGames > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Record: ${state.stats.wins}W - ${state.stats.losses}L - ${state.stats.draws}D (${state.stats.totalGames} played)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerCard({
    required BuildContext context,
    required DotsPlayer player,
    required String displayName,
    required int score,
    required Color color,
    required bool isActiveTurn,
    required IconData icon,
    bool isAiThinking = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isActiveTurn
            ? color.withValues(alpha: isDark ? 0.22 : 0.12)
            : isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActiveTurn ? color : Colors.transparent,
          width: isActiveTurn ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActiveTurn
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: isActiveTurn
                        ? color
                        : isDark
                        ? Colors.white
                        : const Color(0xFF334155),
                  ),
                ),
                if (isAiThinking)
                  const Text(
                    'Thinking...',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE11D48),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

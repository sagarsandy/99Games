import 'package:flutter/material.dart';
import 'package:mini_games_99/app/app_theme.dart';
import 'package:mini_games_99/core/storage/game_stats_storage.dart';
import '../../domain/tic_tac_toe_models.dart';

/// Scoreboard displaying wins, losses, draws and the current active turn.
class TicTacToeScoreboard extends StatelessWidget {
  final GameMode gameMode;
  final PlayerSymbol currentPlayer;
  final GameStats stats;
  final bool isAiThinking;

  const TicTacToeScoreboard({
    super.key,
    required this.gameMode,
    required this.currentPlayer,
    required this.stats,
    required this.isAiThinking,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final xLabel = gameMode == GameMode.vsAi ? 'You (X)' : 'Player X';
    final oLabel = gameMode == GameMode.vsAi ? 'AI (O)' : 'Player O';

    final isXTurn = currentPlayer == PlayerSymbol.x;
    final isOTurn = currentPlayer == PlayerSymbol.o;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildScoreItem(
            context: context,
            title: xLabel,
            score: stats.wins,
            color: AppTheme.playerXColor,
            isActive: isXTurn,
            symbol: 'X',
          ),
          Container(
            height: 38,
            width: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
          _buildScoreItem(
            context: context,
            title: 'Draws',
            score: stats.draws,
            color: isDark ? Colors.white70 : Colors.black54,
            isActive: false,
            symbol: '-',
          ),
          Container(
            height: 38,
            width: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
          _buildScoreItem(
            context: context,
            title: oLabel,
            score: stats.losses,
            color: AppTheme.playerOColor,
            isActive: isOTurn,
            symbol: 'O',
            isThinking: isAiThinking && gameMode == GameMode.vsAi,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem({
    required BuildContext context,
    required String title,
    required int score,
    required Color color,
    required bool isActive,
    required String symbol,
    bool isThinking = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              if (isThinking) ...[
                const SizedBox(width: 4),
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppTheme.playerOColor),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

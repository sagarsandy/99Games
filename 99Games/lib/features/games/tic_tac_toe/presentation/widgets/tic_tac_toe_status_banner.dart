import 'package:flutter/material.dart';
import 'package:mini_games_99/app/app_theme.dart';
import '../../domain/tic_tac_toe_models.dart';

/// Banner displaying current turn, AI thinking status, or match outcome.
class TicTacToeStatusBanner extends StatelessWidget {
  final GameStatus status;
  final PlayerSymbol currentPlayer;
  final PlayerSymbol? winner;
  final GameMode gameMode;
  final bool isAiThinking;

  const TicTacToeStatusBanner({
    super.key,
    required this.status,
    required this.currentPlayer,
    required this.winner,
    required this.gameMode,
    required this.isAiThinking,
  });

  @override
  Widget build(BuildContext context) {
    final (message, color, icon) = _resolveStatusDetails();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, IconData) _resolveStatusDetails() {
    if (status == GameStatus.win) {
      if (gameMode == GameMode.vsAi) {
        if (winner == PlayerSymbol.x) {
          return (
            'Victory! You won!',
            AppTheme.accentSuccess,
            Icons.emoji_events_rounded,
          );
        } else {
          return (
            'Defeat! AI won!',
            AppTheme.playerOColor,
            Icons.smart_toy_rounded,
          );
        }
      } else {
        final winnerName = winner == PlayerSymbol.x ? 'Player X' : 'Player O';
        return (
          '$winnerName Wins!',
          winner == PlayerSymbol.x
              ? AppTheme.playerXColor
              : AppTheme.playerOColor,
          Icons.emoji_events_rounded,
        );
      }
    }

    if (status == GameStatus.draw) {
      return ("It's a Draw!", AppTheme.accentWarning, Icons.handshake_rounded);
    }

    if (isAiThinking) {
      return (
        'AI is thinking...',
        AppTheme.playerOColor,
        Icons.psychology_rounded,
      );
    }

    if (gameMode == GameMode.vsAi) {
      return ('Your Turn (X)', AppTheme.playerXColor, Icons.touch_app_rounded);
    } else {
      final name = currentPlayer == PlayerSymbol.x ? 'Player X' : 'Player O';
      final color = currentPlayer == PlayerSymbol.x
          ? AppTheme.playerXColor
          : AppTheme.playerOColor;
      return ("$name's Turn", color, Icons.touch_app_rounded);
    }
  }
}

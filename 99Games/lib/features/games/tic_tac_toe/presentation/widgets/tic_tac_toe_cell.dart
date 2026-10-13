import 'package:flutter/material.dart';
import 'package:mini_games_99/app/app_theme.dart';
import '../../domain/tic_tac_toe_models.dart';

/// An interactive cell within the 3x3 Tic-Tac-Toe grid.
class TicTacToeCell extends StatelessWidget {
  final int index;
  final PlayerSymbol symbol;
  final bool isWinningCell;
  final bool isEnabled;
  final VoidCallback onTap;

  const TicTacToeCell({
    super.key,
    required this.index,
    required this.symbol,
    required this.isWinningCell,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    final winningBgColor = isDark
        ? AppTheme.accentSuccess.withValues(alpha: 0.28)
        : AppTheme.accentSuccess.withValues(alpha: 0.16);

    final borderColor = isWinningCell
        ? AppTheme.accentSuccess
        : (isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06));

    return Semantics(
      label:
          'Cell ${index + 1}, ${symbol.isNone ? 'empty' : symbol.displayName}',
      button: symbol.isNone && isEnabled,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isWinningCell ? winningBgColor : baseBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isWinningCell ? 2.5 : 1.2,
          ),
          boxShadow: isWinningCell
              ? [
                  BoxShadow(
                    color: AppTheme.accentSuccess.withValues(alpha: 0.25),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled && symbol.isNone ? onTap : null,
            borderRadius: BorderRadius.circular(16),
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.06),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.elasticOut,
                    ),
                    child: child,
                  );
                },
                child: _buildSymbolWidget(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSymbolWidget(BuildContext context) {
    if (symbol.isNone) {
      return const SizedBox.shrink();
    }

    final isX = symbol == PlayerSymbol.x;
    final color = isX ? AppTheme.playerXColor : AppTheme.playerOColor;

    return Text(
      symbol.displayName,
      key: ValueKey('${symbol.name}_$index'),
      style: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: color,
        height: 1.0,
      ),
    );
  }
}

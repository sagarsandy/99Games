import 'package:flutter/material.dart';
import '../../cubit/number_match_cubit.dart';
import '../../cubit/number_match_state.dart';

/// Game controls for Number Match: Hint, Undo, Add Numbers, and Restart.
class NumberMatchControls extends StatelessWidget {
  final NumberMatchState state;
  final NumberMatchCubit cubit;
  final VoidCallback onRestart;

  const NumberMatchControls({
    super.key,
    required this.state,
    required this.cubit,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = state.activeCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Hint Button
          _ControlButton(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Hint',
            color: const Color(0xFFF59E0B),
            onPressed: state.isWon ? null : () => cubit.requestHint(),
          ),

          // 2. Undo Button
          _ControlButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            color: const Color(0xFF64748B),
            onPressed: state.canUndo ? () => cubit.undo() : null,
          ),

          // 3. Add Numbers Button
          _ControlButton(
            icon: Icons.add_circle_outline_rounded,
            label: 'Add (+$activeCount)',
            color: const Color(0xFF6366F1),
            isPrimary: true,
            onPressed: state.isWon || activeCount == 0
                ? null
                : () => cubit.addNumbers(),
          ),

          // 4. Restart Button
          _ControlButton(
            icon: Icons.refresh_rounded,
            label: 'Restart',
            color: const Color(0xFFEF4444),
            onPressed: onRestart,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isPrimary;
  final VoidCallback? onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    this.isPrimary = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = onPressed != null;

    final bg = isPrimary
        ? (isEnabled ? color : color.withValues(alpha: 0.3))
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));

    final fg = isPrimary
        ? Colors.white
        : (isEnabled ? color : (isDark ? Colors.white24 : Colors.black26));

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? null
              : Border.all(
                  color: isEnabled
                      ? color.withValues(alpha: 0.25)
                      : Colors.transparent,
                  width: 1,
                ),
          boxShadow: isPrimary && isEnabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

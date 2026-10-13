import 'package:flutter/material.dart';
import '../../cubit/home_state.dart';

/// Reusable card widget for displaying a mini game in the catalog.
class GameCard extends StatelessWidget {
  final GameInfo game;
  final VoidCallback onPlay;

  const GameCard({super.key, required this.game, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    final borderColor = game.isPlayable
        ? game.accentColor.withValues(alpha: isDark ? 0.4 : 0.3)
        : (isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05));

    return Card(
      elevation: game.isPlayable ? 3 : 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: borderColor,
          width: game.isPlayable ? 1.5 : 1.0,
        ),
      ),
      color: cardBgColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (game.isPlayable) {
            onPlay();
          } else {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${game.title} is coming soon in a future update!',
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(milliseconds: 1800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon badge & status chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: game.isPlayable
                          ? game.accentColor.withValues(alpha: 0.15)
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      game.icon,
                      color: game.isPlayable
                          ? game.accentColor
                          : (isDark ? Colors.white38 : Colors.black38),
                      size: 24,
                    ),
                  ),
                  _buildStatusBadge(context),
                ],
              ),
              const Spacer(),
              // Title
              Text(
                game.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: game.isPlayable
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.white54 : Colors.black45),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Description
              Text(
                game.description,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Footer: Category / Player tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    game.playerLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  if (game.isPlayable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: game.accentColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Play',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    if (game.isPlayable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'READY',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF10B981),
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 10, color: Colors.grey),
          SizedBox(width: 3),
          Text(
            'SOON',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

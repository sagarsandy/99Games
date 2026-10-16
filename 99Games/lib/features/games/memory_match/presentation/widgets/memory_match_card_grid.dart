import 'package:flutter/material.dart';
import '../../domain/memory_match_models.dart';
import 'memory_match_card.dart';

/// Responsive card grid that dynamically computes optimal card dimensions,
/// aspect ratios, and padding to fit all screen sizes (2x2 up to 5x6) cleanly
/// without overflow.
class MemoryMatchCardGrid extends StatelessWidget {
  final LevelConfig config;
  final List<MemoryCard> cards;
  final int? firstSelectedId;
  final int? secondSelectedId;
  final bool isResolvingMismatch;
  final ValueChanged<MemoryCard> onCardTap;

  const MemoryMatchCardGrid({
    super.key,
    required this.config,
    required this.cards,
    this.firstSelectedId,
    this.secondSelectedId,
    this.isResolvingMismatch = false,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // Determine optimal columns and rows based on screen orientation
        final isPortrait = availableHeight >= availableWidth;
        int cols = config.cols;
        int rows = config.rows;

        // In portrait mode, favor having fewer columns and more rows so cards are larger
        if (isPortrait && cols > rows) {
          cols = config.rows;
          rows = config.cols;
        } else if (!isPortrait && rows > cols) {
          cols = config.rows;
          rows = config.cols;
        }

        final cardCount = cards.length;
        final spacing = cardCount >= 20 ? 6.0 : (cardCount >= 12 ? 8.0 : 12.0);
        final horizontalPadding = cardCount >= 20 ? 8.0 : 12.0;
        final verticalPadding = cardCount >= 20 ? 6.0 : 10.0;

        final maxGridWidth = availableWidth - (horizontalPadding * 2);
        final maxGridHeight = availableHeight - (verticalPadding * 2);

        // Maximum card width possible to fit columns
        final maxCardWidth = (maxGridWidth - (cols - 1) * spacing) / cols;
        // Maximum card height possible to fit rows without scrolling
        final maxCardHeight = (maxGridHeight - (rows - 1) * spacing) / rows;

        // Determine card aspect ratio (target ~0.78 for playing card feel)
        double cardWidth;
        double cardHeight;

        final targetRatio = 0.78; // width / height
        final heightFromWidth = maxCardWidth / targetRatio;

        if (heightFromWidth <= maxCardHeight) {
          // Width is the constraint; cards fit within height comfortably
          cardWidth = maxCardWidth;
          cardHeight = heightFromWidth;
        } else {
          // Height is the constraint; scale down to fit available height
          cardHeight = maxCardHeight;
          cardWidth = cardHeight * targetRatio;
          if (cardWidth > maxCardWidth) {
            cardWidth = maxCardWidth;
          }
        }

        // Cap card size on large tablets/desktop so 2x2 doesn't look enormous
        const maxSingleCardWidth = 140.0;
        if (cardWidth > maxSingleCardWidth) {
          cardWidth = maxSingleCardWidth;
          cardHeight = cardWidth / targetRatio;
        }

        final totalGridWidth = (cardWidth * cols) + ((cols - 1) * spacing);
        final totalGridHeight = (cardHeight * rows) + ((rows - 1) * spacing);

        final fitsWithoutScroll = totalGridHeight <= maxGridHeight + 2;

        return Center(
          child: SingleChildScrollView(
            physics: fitsWithoutScroll
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: SizedBox(
              width: totalGridWidth,
              height: totalGridHeight,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: cardWidth / cardHeight,
                ),
                itemBuilder: (context, index) {
                  final card = cards[index];
                  final isSelected =
                      card.id == firstSelectedId || card.id == secondSelectedId;
                  final isMismatching =
                      isResolvingMismatch &&
                      (card.id == firstSelectedId ||
                          card.id == secondSelectedId);

                  return MemoryMatchCard(
                    key: ValueKey(card.id),
                    card: card,
                    isSelected: isSelected,
                    isMismatching: isMismatching,
                    isInteractive: !isResolvingMismatch && !card.isMatched,
                    onTap: () => onCardTap(card),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

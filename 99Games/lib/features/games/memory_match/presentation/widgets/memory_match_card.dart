import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/memory_match_models.dart';
import '../painters/memory_match_artwork_painter.dart';
import '../painters/memory_match_card_back_painter.dart';

/// Interactive memory card widget with smooth 3D perspective flip animation,
/// custom-painted front cartoon artwork, custom-painted card back,
/// and subtle celebration styling when matched.
class MemoryMatchCard extends StatefulWidget {
  final MemoryCard card;
  final bool isSelected;
  final bool isMismatching;
  final bool isInteractive;
  final VoidCallback onTap;

  const MemoryMatchCard({
    super.key,
    required this.card,
    this.isSelected = false,
    this.isMismatching = false,
    this.isInteractive = true,
    required this.onTap,
  });

  @override
  State<MemoryMatchCard> createState() => _MemoryMatchCardState();
}

class _MemoryMatchCardState extends State<MemoryMatchCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: widget.card.isFaceUp ? 1.0 : 0.0,
    );

    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.94),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.94, end: 1.0),
        weight: 50,
      ),
    ]).animate(_flipController);
  }

  @override
  void didUpdateWidget(covariant MemoryMatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.card.isFaceUp != oldWidget.card.isFaceUp) {
      if (widget.card.isFaceUp) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isInteractive) return;
    if (widget.card.isMatched || widget.card.isFaceUp) return;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final flipVal = _flipAnimation.value;
          // Angle in radians from 0 (back) to pi (front)
          final angle = flipVal * math.pi;
          final isFaceUp = angle > (math.pi / 2);

          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0018) // perspective
                ..rotateY(angle),
              alignment: Alignment.center,
              child: isFaceUp
                  ? Transform(
                      // Counter-flip so front content is not mirrored
                      transform: Matrix4.identity()..rotateY(math.pi),
                      alignment: Alignment.center,
                      child: _buildFront(),
                    )
                  : _buildBack(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: const CustomPaint(
          painter: MemoryMatchCardBackPainter(),
          child: SizedBox.expand(),
        ),
      ),
    );
  }

  Widget _buildFront() {
    final isMatched = widget.card.isMatched;
    final isMismatch = widget.isMismatching;

    Color borderColor;
    Color glowColor;
    double borderWidth = 2.0;

    if (isMatched) {
      borderColor = const Color(0xFF10B981); // Emerald match
      glowColor = const Color(0xFF10B981).withValues(alpha: 0.35);
      borderWidth = 2.5;
    } else if (isMismatch) {
      borderColor = const Color(0xFFEF4444); // Crimson mismatch
      glowColor = const Color(0xFFEF4444).withValues(alpha: 0.35);
      borderWidth = 2.5;
    } else if (widget.isSelected) {
      borderColor = const Color(0xFF6366F1); // Indigo selection
      glowColor = const Color(0xFF6366F1).withValues(alpha: 0.3);
      borderWidth = 2.5;
    } else {
      borderColor = const Color(0xFFE2E8F0);
      glowColor = Colors.black.withValues(alpha: 0.08);
      borderWidth = 1.5;
    }

    return Container(
      decoration: BoxDecoration(
        color: isMatched
            ? const Color(0xFFF0FDF4)
            : isMismatch
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: isMatched || isMismatch ? 10 : 5,
            spreadRadius: isMatched || isMismatch ? 1 : 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle inner radial gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    Colors.white,
                    isMatched
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF8FAFC),
                  ],
                ),
              ),
            ),
          ),

          // Central CustomPainter Artwork
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: CustomPaint(
                  painter: MemoryMatchArtworkPainter(
                    artwork: widget.card.artwork,
                  ),
                ),
              ),
            ),
          ),

          // Success badge for matched cards
          if (isMatched)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

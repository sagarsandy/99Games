import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games_99/features/games/dots_and_boxes/domain/dots_and_boxes_models.dart';

void main() {
  group('Dots and Boxes - Board Sizes & Dimensions', () {
    test(
      'Small board has 6x6 boxes, 7x7 dots, 36 total boxes, 84 total edges',
      () {
        const size = BoardSize.small;
        expect(size.rows, equals(6));
        expect(size.cols, equals(6));
        expect(size.dotRows, equals(7));
        expect(size.dotCols, equals(7));
        expect(size.totalBoxes, equals(36));
        expect(size.totalHorizontalEdges, equals(42)); // (6 + 1) * 6
        expect(size.totalVerticalEdges, equals(42)); // 6 * (6 + 1)
        expect(size.totalEdges, equals(84));
        expect(size.label, contains('6×6'));
        expect(size.dimensionsText, equals('6 × 6'));
        expect(size.boxCountText, equals('36 boxes'));
        expect(size.dotCountText, equals('7 × 7 dots'));
      },
    );

    test(
      'Medium board has 9x9 boxes, 10x10 dots, 81 total boxes, 180 total edges',
      () {
        const size = BoardSize.medium;
        expect(size.rows, equals(9));
        expect(size.cols, equals(9));
        expect(size.dotRows, equals(10));
        expect(size.dotCols, equals(10));
        expect(size.totalBoxes, equals(81));
        expect(size.totalHorizontalEdges, equals(90)); // (9 + 1) * 9
        expect(size.totalVerticalEdges, equals(90)); // 9 * (9 + 1)
        expect(size.totalEdges, equals(180));
        expect(size.label, contains('9×9'));
        expect(size.dimensionsText, equals('9 × 9'));
        expect(size.boxCountText, equals('81 boxes'));
        expect(size.dotCountText, equals('10 × 10 dots'));
      },
    );

    test(
      'Large board has 15x15 boxes, 16x16 dots, 225 total boxes, 480 total edges',
      () {
        const size = BoardSize.large;
        expect(size.rows, equals(15));
        expect(size.cols, equals(15));
        expect(size.dotRows, equals(16));
        expect(size.dotCols, equals(16));
        expect(size.totalBoxes, equals(225));
        expect(size.totalHorizontalEdges, equals(240)); // (15 + 1) * 15
        expect(size.totalVerticalEdges, equals(240)); // 15 * (15 + 1)
        expect(size.totalEdges, equals(480));
        expect(size.label, contains('15×15'));
        expect(size.dimensionsText, equals('15 × 15'));
        expect(size.boxCountText, equals('225 boxes'));
        expect(size.dotCountText, equals('16 × 16 dots'));
      },
    );
  });

  group('Dots and Boxes - Models & Enums', () {
    test('DotsPlayer switching and display names', () {
      expect(DotsPlayer.player1.opposite, equals(DotsPlayer.player2));
      expect(DotsPlayer.player2.opposite, equals(DotsPlayer.player1));

      expect(DotsPlayer.player1.displayName(DotsGameMode.vsAi), equals('You'));
      expect(
        DotsPlayer.player2.displayName(DotsGameMode.vsAi),
        equals('Computer'),
      );

      expect(
        DotsPlayer.player1.displayName(DotsGameMode.passAndPlay),
        equals('Player 1'),
      );
      expect(
        DotsPlayer.player2.displayName(DotsGameMode.passAndPlay),
        equals('Player 2'),
      );

      expect(DotsPlayer.player1.shortBadge(DotsGameMode.vsAi), equals('Y'));
      expect(DotsPlayer.player2.shortBadge(DotsGameMode.vsAi), equals('C'));
      expect(
        DotsPlayer.player1.shortBadge(DotsGameMode.passAndPlay),
        equals('1'),
      );
      expect(
        DotsPlayer.player2.shortBadge(DotsGameMode.passAndPlay),
        equals('2'),
      );
    });

    test('EdgePosition equality and properties', () {
      const e1 = EdgePosition.horizontal(2, 3);
      const e2 = EdgePosition(
        orientation: EdgeOrientation.horizontal,
        row: 2,
        col: 3,
      );
      const e3 = EdgePosition.vertical(2, 3);

      expect(e1, equals(e2));
      expect(e1, isNot(equals(e3)));
      expect(e1.isHorizontal, isTrue);
      expect(e1.isVertical, isFalse);
      expect(e3.isHorizontal, isFalse);
      expect(e3.isVertical, isTrue);
      expect(e1.toString(), equals('H(2, 3)'));
      expect(e3.toString(), equals('V(2, 3)'));
    });

    test('BoxPosition equality and toString', () {
      const b1 = BoxPosition(1, 2);
      const b2 = BoxPosition(1, 2);
      const b3 = BoxPosition(2, 1);

      expect(b1, equals(b2));
      expect(b1, isNot(equals(b3)));
      expect(b1.toString(), equals('Box(1, 2)'));
    });

    test('DotsGameMode and DotsAiDifficulty labels', () {
      expect(DotsGameMode.vsAi.label, equals('vs Computer'));
      expect(DotsGameMode.passAndPlay.label, equals('2 Players'));

      expect(DotsAiDifficulty.easy.label, equals('Easy'));
      expect(DotsAiDifficulty.medium.label, equals('Medium'));
      expect(DotsAiDifficulty.hard.label, equals('Hard'));
    });

    test('DotsGameStatus completion check', () {
      expect(DotsGameStatus.inProgress.isGameOver, isFalse);
      expect(DotsGameStatus.completed.isGameOver, isTrue);
    });
  });
}

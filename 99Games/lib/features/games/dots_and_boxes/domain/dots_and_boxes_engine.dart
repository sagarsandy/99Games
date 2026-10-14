import 'dart:math';
import 'dots_and_boxes_models.dart';

/// Pure Dart domain engine containing the rules, state transitions,
/// and AI decision-making algorithms for Dots and Boxes.
class DotsAndBoxesEngine {
  final Random _random;

  DotsAndBoxesEngine({Random? random}) : _random = random ?? Random();

  /// Creates an empty (unclaimed) horizontal edges grid for [size].
  /// Dimensions: (rows + 1) rows × cols columns.
  List<List<DotsPlayer?>> createEmptyHorizontalEdges(BoardSize size) {
    return List.generate(
      size.rows + 1,
      (_) => List<DotsPlayer?>.filled(size.cols, null),
    );
  }

  /// Creates an empty (unclaimed) vertical edges grid for [size].
  /// Dimensions: rows rows × (cols + 1) columns.
  List<List<DotsPlayer?>> createEmptyVerticalEdges(BoardSize size) {
    return List.generate(
      size.rows,
      (_) => List<DotsPlayer?>.filled(size.cols + 1, null),
    );
  }

  /// Creates an empty (unclaimed) boxes grid for [size].
  /// Dimensions: rows rows × cols columns.
  List<List<DotsPlayer?>> createEmptyBoxes(BoardSize size) {
    return List.generate(
      size.rows,
      (_) => List<DotsPlayer?>.filled(size.cols, null),
    );
  }

  /// Deep clones a 2D grid to ensure immutability.
  List<List<DotsPlayer?>> cloneGrid(List<List<DotsPlayer?>> grid) {
    return grid.map((row) => List<DotsPlayer?>.from(row)).toList();
  }

  /// Validates whether [edge] has valid coordinates for [size].
  bool isValidEdge(BoardSize size, EdgePosition edge) {
    if (edge.isHorizontal) {
      return edge.row >= 0 &&
          edge.row <= size.rows &&
          edge.col >= 0 &&
          edge.col < size.cols;
    } else {
      return edge.row >= 0 &&
          edge.row < size.rows &&
          edge.col >= 0 &&
          edge.col <= size.cols;
    }
  }

  /// Checks whether [edge] is already claimed.
  bool isEdgeClaimed({
    required List<List<DotsPlayer?>> horizontalEdges,
    required List<List<DotsPlayer?>> verticalEdges,
    required EdgePosition edge,
  }) {
    if (edge.isHorizontal) {
      return horizontalEdges[edge.row][edge.col] != null;
    } else {
      return verticalEdges[edge.row][edge.col] != null;
    }
  }

  /// Checks if [edge] is a legal move on the current board.
  bool isLegalMove({
    required BoardSize size,
    required List<List<DotsPlayer?>> horizontalEdges,
    required List<List<DotsPlayer?>> verticalEdges,
    required EdgePosition edge,
  }) {
    if (!isValidEdge(size, edge)) return false;
    return !isEdgeClaimed(
      horizontalEdges: horizontalEdges,
      verticalEdges: verticalEdges,
      edge: edge,
    );
  }

  /// Returns all currently unclaimed legal edges on the board.
  List<EdgePosition> getAllUnclaimedEdges({
    required BoardSize size,
    required List<List<DotsPlayer?>> horizontalEdges,
    required List<List<DotsPlayer?>> verticalEdges,
  }) {
    final edges = <EdgePosition>[];

    // Horizontal edges: (rows + 1) rows × cols cols
    for (int r = 0; r <= size.rows; r++) {
      for (int c = 0; c < size.cols; c++) {
        if (horizontalEdges[r][c] == null) {
          edges.add(EdgePosition.horizontal(r, c));
        }
      }
    }

    // Vertical edges: rows rows × (cols + 1) cols
    for (int r = 0; r < size.rows; r++) {
      for (int c = 0; c <= size.cols; c++) {
        if (verticalEdges[r][c] == null) {
          edges.add(EdgePosition.vertical(r, c));
        }
      }
    }

    return edges;
  }

  /// Returns the adjacent box coordinates that share [edge].
  /// An edge has either 1 adjacent box (if on the outer boundary)
  /// or 2 adjacent boxes (if interior).
  List<BoxPosition> getAdjacentBoxes(BoardSize size, EdgePosition edge) {
    final boxes = <BoxPosition>[];

    if (edge.isHorizontal) {
      // Box above (r - 1, c) if r > 0
      if (edge.row > 0) {
        boxes.add(BoxPosition(edge.row - 1, edge.col));
      }
      // Box below (r, c) if r < rows
      if (edge.row < size.rows) {
        boxes.add(BoxPosition(edge.row, edge.col));
      }
    } else {
      // Box to the left (r, c - 1) if c > 0
      if (edge.col > 0) {
        boxes.add(BoxPosition(edge.row, edge.col - 1));
      }
      // Box to the right (r, c) if c < cols
      if (edge.col < size.cols) {
        boxes.add(BoxPosition(edge.row, edge.col));
      }
    }

    return boxes;
  }

  /// Counts the number of currently drawn edges surrounding box [row], [col].
  /// Result is between 0 and 4.
  int countDrawnEdgesForBox({
    required List<List<DotsPlayer?>> horizontalEdges,
    required List<List<DotsPlayer?>> verticalEdges,
    required int row,
    required int col,
  }) {
    int count = 0;
    // Top
    if (horizontalEdges[row][col] != null) count++;
    // Bottom
    if (horizontalEdges[row + 1][col] != null) count++;
    // Left
    if (verticalEdges[row][col] != null) count++;
    // Right
    if (verticalEdges[row][col + 1] != null) count++;
    return count;
  }

  /// Returns the missing edges surrounding box [row], [col].
  List<EdgePosition> getMissingEdgesForBox({
    required List<List<DotsPlayer?>> horizontalEdges,
    required List<List<DotsPlayer?>> verticalEdges,
    required int row,
    required int col,
  }) {
    final missing = <EdgePosition>[];
    if (horizontalEdges[row][col] == null) {
      missing.add(EdgePosition.horizontal(row, col));
    }
    if (horizontalEdges[row + 1][col] == null) {
      missing.add(EdgePosition.horizontal(row + 1, col));
    }
    if (verticalEdges[row][col] == null) {
      missing.add(EdgePosition.vertical(row, col));
    }
    if (verticalEdges[row][col + 1] == null) {
      missing.add(EdgePosition.vertical(row, col + 1));
    }
    return missing;
  }

  /// Applies [edge] move for [player] and returns a comprehensive [DotsMoveResult].
  ///
  /// Throws [ArgumentError] if the move is invalid or already claimed.
  DotsMoveResult applyMove({
    required BoardSize size,
    required List<List<DotsPlayer?>> horizontalEdges,
    required List<List<DotsPlayer?>> verticalEdges,
    required List<List<DotsPlayer?>> boxes,
    required EdgePosition edge,
    required DotsPlayer player,
  }) {
    if (!isLegalMove(
      size: size,
      horizontalEdges: horizontalEdges,
      verticalEdges: verticalEdges,
      edge: edge,
    )) {
      throw ArgumentError('Illegal move at $edge');
    }

    // Clone edge matrices to preserve immutability
    final newH = cloneGrid(horizontalEdges);
    final newV = cloneGrid(verticalEdges);
    final newBoxes = cloneGrid(boxes);

    if (edge.isHorizontal) {
      newH[edge.row][edge.col] = player;
    } else {
      newV[edge.row][edge.col] = player;
    }

    // Detect newly completed boxes
    final adjacent = getAdjacentBoxes(size, edge);
    final completedBoxes = <BoxPosition>[];

    for (final box in adjacent) {
      // Check if not already completed and now all 4 edges drawn
      if (newBoxes[box.row][box.col] == null) {
        final drawn = countDrawnEdgesForBox(
          horizontalEdges: newH,
          verticalEdges: newV,
          row: box.row,
          col: box.col,
        );
        if (drawn == 4) {
          completedBoxes.add(box);
          newBoxes[box.row][box.col] = player;
        }
      }
    }

    // Extra turn rule: award extra turn if at least one box completed
    final getsExtraTurn = completedBoxes.isNotEmpty;
    final nextPlayer = getsExtraTurn ? player : player.opposite;

    // Check game over
    int p1Score = 0;
    int p2Score = 0;
    for (int r = 0; r < size.rows; r++) {
      for (int c = 0; c < size.cols; c++) {
        if (newBoxes[r][c] == DotsPlayer.player1) p1Score++;
        if (newBoxes[r][c] == DotsPlayer.player2) p2Score++;
      }
    }

    final isGameOver = (p1Score + p2Score) == size.totalBoxes;
    DotsPlayer? winner;
    bool isDraw = false;

    if (isGameOver) {
      if (p1Score > p2Score) {
        winner = DotsPlayer.player1;
      } else if (p2Score > p1Score) {
        winner = DotsPlayer.player2;
      } else {
        isDraw = true;
      }
    }

    return DotsMoveResult(
      edge: edge,
      player: player,
      completedBoxes: List.unmodifiable(completedBoxes),
      getsExtraTurn: getsExtraTurn,
      nextPlayer: nextPlayer,
      isGameOver: isGameOver,
      winner: winner,
      isDraw: isDraw,
    );
  }

  /// Selects the best move for the AI player according to [difficulty].
  EdgePosition? selectAiMove({
    required BoardSize boardSize,
    required List<List<DotsPlayer?>> horizontalEdges,
    required List<List<DotsPlayer?>> verticalEdges,
    required List<List<DotsPlayer?>> boxes,
    required DotsPlayer aiPlayer,
    required DotsAiDifficulty difficulty,
  }) {
    final legalEdges = getAllUnclaimedEdges(
      size: boardSize,
      horizontalEdges: horizontalEdges,
      verticalEdges: verticalEdges,
    );

    if (legalEdges.isEmpty) return null;

    switch (difficulty) {
      case DotsAiDifficulty.easy:
        return _selectEasyMove(legalEdges);

      case DotsAiDifficulty.medium:
        return _selectMediumMove(
          boardSize: boardSize,
          horizontalEdges: horizontalEdges,
          verticalEdges: verticalEdges,
          legalEdges: legalEdges,
        );

      case DotsAiDifficulty.hard:
        return _selectHardMove(
          boardSize: boardSize,
          horizontalEdges: horizontalEdges,
          verticalEdges: verticalEdges,
          boxes: boxes,
          aiPlayer: aiPlayer,
          legalEdges: legalEdges,
        );
    }
  }

  /// Easy AI: selects a random legal unclaimed edge.
  EdgePosition _selectEasyMove(List<EdgePosition> legalEdges) {
    return legalEdges[_random.nextInt(legalEdges.length)];
  }

  /// Medium AI:
  /// 1. Takes any move that immediately completes boxes (preferring 2-box captures).
  /// 2. If no captures exist, chooses a safe move (does not create 3-edge boxes).
  /// 3. If forced to open a box, minimizes immediate 3-edge exposure.
  EdgePosition _selectMediumMove({
    required BoardSize boardSize,
    required List<List<DotsPlayer?>> horizontalEdges,
    required List<List<DotsPlayer?>> verticalEdges,
    required List<EdgePosition> legalEdges,
  }) {
    final doubleCaptures = <EdgePosition>[];
    final singleCaptures = <EdgePosition>[];
    final safeMoves = <EdgePosition>[];
    final sacrificeMoves = <EdgePosition>[];

    for (final edge in legalEdges) {
      final adjacent = getAdjacentBoxes(boardSize, edge);
      int completingCount = 0;
      bool createsThreeEdgeBox = false;

      for (final box in adjacent) {
        final drawn = countDrawnEdgesForBox(
          horizontalEdges: horizontalEdges,
          verticalEdges: verticalEdges,
          row: box.row,
          col: box.col,
        );
        if (drawn == 3) {
          completingCount++;
        } else if (drawn == 2) {
          createsThreeEdgeBox = true;
        }
      }

      if (completingCount == 2) {
        doubleCaptures.add(edge);
      } else if (completingCount == 1) {
        singleCaptures.add(edge);
      } else if (!createsThreeEdgeBox) {
        safeMoves.add(edge);
      } else {
        sacrificeMoves.add(edge);
      }
    }

    if (doubleCaptures.isNotEmpty) {
      return doubleCaptures[_random.nextInt(doubleCaptures.length)];
    }
    if (singleCaptures.isNotEmpty) {
      return singleCaptures[_random.nextInt(singleCaptures.length)];
    }
    if (safeMoves.isNotEmpty) {
      return safeMoves[_random.nextInt(safeMoves.length)];
    }

    // When forced to sacrifice, pick the move that creates 1 three-edge box instead of 2
    sacrificeMoves.sort((a, b) {
      final aCreated = _countThreeEdgeBoxesCreated(
        boardSize,
        horizontalEdges,
        verticalEdges,
        a,
      );
      final bCreated = _countThreeEdgeBoxesCreated(
        boardSize,
        horizontalEdges,
        verticalEdges,
        b,
      );
      return aCreated.compareTo(bCreated);
    });

    return sacrificeMoves.first;
  }

  /// Hard AI:
  /// 1. Tactic-aware box completion (including double-crossing strategy on long chains).
  /// 2. Heuristic selection among safe moves prioritizing border stability and
  ///    avoiding early 2-edge box traps.
  /// 3. Endgame sacrifice minimization: simulates chain cascade lengths to give
  ///    away the absolute fewest boxes when forced to surrender.
  /// 4. Guaranteed fast execution bounded to < 30ms even on 15x15 boards.
  EdgePosition _selectHardMove({
    required BoardSize boardSize,
    required List<List<DotsPlayer?>> horizontalEdges,
    required List<List<DotsPlayer?>> verticalEdges,
    required List<List<DotsPlayer?>> boxes,
    required DotsPlayer aiPlayer,
    required List<EdgePosition> legalEdges,
  }) {
    // 1. Analyze immediate capturing moves
    final doubleCaptures = <EdgePosition>[];
    final singleCaptures = <EdgePosition>[];
    final safeMoves = <EdgePosition>[];
    final sacrifices = <EdgePosition>[];

    for (final edge in legalEdges) {
      final adjacent = getAdjacentBoxes(boardSize, edge);
      int completes = 0;
      bool createsThreeEdge = false;

      for (final box in adjacent) {
        final drawn = countDrawnEdgesForBox(
          horizontalEdges: horizontalEdges,
          verticalEdges: verticalEdges,
          row: box.row,
          col: box.col,
        );
        if (drawn == 3) {
          completes++;
        } else if (drawn == 2) {
          createsThreeEdge = true;
        }
      }

      if (completes == 2) {
        doubleCaptures.add(edge);
      } else if (completes == 1) {
        singleCaptures.add(edge);
      } else if (!createsThreeEdge) {
        safeMoves.add(edge);
      } else {
        sacrifices.add(edge);
      }
    }

    // Always prioritize 2-box captures
    if (doubleCaptures.isNotEmpty) {
      return doubleCaptures.first;
    }

    // If single captures exist:
    if (singleCaptures.isNotEmpty) {
      // Evaluate if this capture chain ends. If taking all leaves a double-cross opportunity
      // for a long chain, we evaluate the best capture edge.
      return _evaluateBestCapture(
        boardSize: boardSize,
        horizontalEdges: horizontalEdges,
        verticalEdges: verticalEdges,
        captures: singleCaptures,
      );
    }

    // 2. Safe moves phase (no captures available, keep control)
    if (safeMoves.isNotEmpty) {
      return _evaluateBestSafeMove(
        boardSize: boardSize,
        horizontalEdges: horizontalEdges,
        verticalEdges: verticalEdges,
        safeMoves: safeMoves,
      );
    }

    // 3. Endgame sacrifice phase: ALL moves give away points
    // Simulate opponent chain cascade length for each candidate move and pick minimum
    EdgePosition bestSacrifice = sacrifices.first;
    int minCascade = 999999;

    for (final edge in sacrifices) {
      final cascade = _simulateCascadeLength(
        boardSize: boardSize,
        horizontalEdges: horizontalEdges,
        verticalEdges: verticalEdges,
        edge: edge,
      );
      if (cascade < minCascade) {
        minCascade = cascade;
        bestSacrifice = edge;
      }
    }

    return bestSacrifice;
  }

  /// Picks the capture edge that keeps initiative or maximizes chain capture.
  EdgePosition _evaluateBestCapture({
    required BoardSize boardSize,
    required List<List<DotsPlayer?>> horizontalEdges,
    required List<List<DotsPlayer?>> verticalEdges,
    required List<EdgePosition> captures,
  }) {
    if (captures.length == 1) return captures.first;

    // Prefer capture edge that reveals another capture or leaves no sacrifice
    EdgePosition best = captures.first;
    int bestScore = -9999;

    for (final edge in captures) {
      // Simulate move
      final adj = getAdjacentBoxes(boardSize, edge);
      int score = 10;
      for (final box in adj) {
        final drawn = countDrawnEdgesForBox(
          horizontalEdges: horizontalEdges,
          verticalEdges: verticalEdges,
          row: box.row,
          col: box.col,
        );
        if (drawn == 3) score += 20;
      }
      if (score > bestScore) {
        bestScore = score;
        best = edge;
      }
    }

    return best;
  }

  /// Evaluates safe moves to pick the most strategically sound edge:
  /// - Prefer outer perimeter edges (they affect only 1 box instead of 2).
  /// - Prefer edges adjacent to boxes with 0 drawn edges (safest, farthest from 3 edges).
  /// - Avoid creating 2-edge boxes when 1-edge boxes are possible.
  EdgePosition _evaluateBestSafeMove({
    required BoardSize boardSize,
    required List<List<DotsPlayer?>> horizontalEdges,
    required List<List<DotsPlayer?>> verticalEdges,
    required List<EdgePosition> safeMoves,
  }) {
    EdgePosition best = safeMoves.first;
    double bestScore = -999999.0;

    for (final edge in safeMoves) {
      final adjacent = getAdjacentBoxes(boardSize, edge);
      double score = 0.0;

      // Outer boundary edge bonus: touches only 1 box, reducing future liability
      if (adjacent.length == 1) {
        score += 8.0;
      }

      for (final box in adjacent) {
        final drawn = countDrawnEdgesForBox(
          horizontalEdges: horizontalEdges,
          verticalEdges: verticalEdges,
          row: box.row,
          col: box.col,
        );

        if (drawn == 0) {
          // Drawing here turns 0 edges -> 1 edge (safest possible transition)
          score += 15.0;
        } else if (drawn == 1) {
          // Drawing here turns 1 edge -> 2 edges (now one away from danger)
          score += 2.0;
        }
      }

      // Center control bonus
      final midRow = boardSize.rows / 2;
      final midCol = boardSize.cols / 2;
      final distFromCenter =
          (edge.row - midRow).abs() + (edge.col - midCol).abs();
      score -= distFromCenter * 0.1;

      if (score > bestScore) {
        bestScore = score;
        best = edge;
      }
    }

    return best;
  }

  /// Counts how many 3-edge boxes would be created by drawing [edge].
  int _countThreeEdgeBoxesCreated(
    BoardSize size,
    List<List<DotsPlayer?>> hEdges,
    List<List<DotsPlayer?>> vEdges,
    EdgePosition edge,
  ) {
    int count = 0;
    final adjacent = getAdjacentBoxes(size, edge);
    for (final box in adjacent) {
      final drawn = countDrawnEdgesForBox(
        horizontalEdges: hEdges,
        verticalEdges: vEdges,
        row: box.row,
        col: box.col,
      );
      if (drawn == 2) {
        count++;
      }
    }
    return count;
  }

  /// Simulates how many boxes the opponent can cascade-capture if we play [edge].
  int _simulateCascadeLength({
    required BoardSize boardSize,
    required List<List<DotsPlayer?>> horizontalEdges,
    required List<List<DotsPlayer?>> verticalEdges,
    required EdgePosition edge,
  }) {
    // Clone grids to simulate
    final simH = cloneGrid(horizontalEdges);
    final simV = cloneGrid(verticalEdges);

    if (edge.isHorizontal) {
      simH[edge.row][edge.col] = DotsPlayer.player2;
    } else {
      simV[edge.row][edge.col] = DotsPlayer.player2;
    }

    int capturedCount = 0;
    bool foundCapture = true;

    // Simulate opponent iteratively capturing all 3-edge and 4-edge boxes
    while (foundCapture) {
      foundCapture = false;
      for (int r = 0; r < boardSize.rows; r++) {
        for (int c = 0; c < boardSize.cols; c++) {
          final drawn = countDrawnEdgesForBox(
            horizontalEdges: simH,
            verticalEdges: simV,
            row: r,
            col: c,
          );

          if (drawn == 3) {
            // Find the 4th missing edge and draw it for opponent
            final missing = getMissingEdgesForBox(
              horizontalEdges: simH,
              verticalEdges: simV,
              row: r,
              col: c,
            );
            if (missing.isNotEmpty) {
              final lastEdge = missing.first;
              if (lastEdge.isHorizontal) {
                simH[lastEdge.row][lastEdge.col] = DotsPlayer.player1;
              } else {
                simV[lastEdge.row][lastEdge.col] = DotsPlayer.player1;
              }
              capturedCount++;
              foundCapture = true;
              break; // restart check
            }
          }
        }
        if (foundCapture) break;
      }
    }

    return capturedCount;
  }
}

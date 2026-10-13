import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/game_stats_storage.dart';
import '../domain/block_puzzle_engine.dart';
import '../domain/block_puzzle_models.dart';
import 'block_puzzle_state.dart';

/// Cubit managing Block Puzzle state, placement, clearing, and persistence.
class BlockPuzzleCubit extends Cubit<BlockPuzzleState> {
  final GameStatsStorage _statsStorage;
  final BlockPuzzleEngine _engine;

  BlockPuzzleCubit({
    required GameStatsStorage statsStorage,
    BlockPuzzleEngine? engine,
    List<int>? initialBoard,
    List<BlockPiece>? initialPieces,
  }) : _statsStorage = statsStorage,
       _engine = engine ?? BlockPuzzleEngine(),
       super(
         BlockPuzzleState.initial(
           board:
               initialBoard ??
               (engine ?? BlockPuzzleEngine()).createEmptyBoard(),
           pieces:
               initialPieces ??
               (engine ?? BlockPuzzleEngine()).generateNewPieces(),
         ),
       ) {
    loadBestScore();
  }

  /// Loads the persisted best score.
  Future<void> loadBestScore() async {
    try {
      final best = await _statsStorage.getBlockPuzzleBestScore();
      if (!isClosed) {
        emit(state.copyWith(bestScore: best));
      }
    } catch (_) {
      // Graceful error handling
    }
  }

  /// Selects or deselects a piece from the tray.
  void selectPiece(int index) {
    if (state.isGameOver) return;
    if (index < 0 || index >= state.availablePieces.length) {
      emit(
        state.copyWith(selectedPieceIndex: () => null, hoverAnchor: () => null),
      );
      return;
    }

    final piece = state.availablePieces[index];
    if (piece.isUsed) return;

    if (state.selectedPieceIndex == index) {
      // Toggle off
      emit(
        state.copyWith(selectedPieceIndex: () => null, hoverAnchor: () => null),
      );
    } else {
      // Select
      emit(
        state.copyWith(
          selectedPieceIndex: () => index,
          hoverAnchor: () => null,
        ),
      );
    }
  }

  /// Unselects the active piece.
  void unselectPiece() {
    emit(
      state.copyWith(selectedPieceIndex: () => null, hoverAnchor: () => null),
    );
  }

  /// Sets hover anchor for previewing piece placement.
  void setHoverAnchor(int row, int col) {
    if (state.selectedPiece == null || state.isGameOver) return;
    emit(state.copyWith(hoverAnchor: () => BlockCoordinate(row, col)));
  }

  /// Clears placement preview anchor.
  void clearHoverAnchor() {
    if (state.hoverAnchor != null) {
      emit(state.copyWith(hoverAnchor: () => null));
    }
  }

  /// Places the selected (or explicitly passed) piece at ([anchorRow], [anchorCol]).
  Future<bool> placePieceAt(
    int anchorRow,
    int anchorCol, {
    BlockPiece? explicitPiece,
  }) async {
    if (state.isGameOver) return false;

    final pieceToPlace = explicitPiece ?? state.selectedPiece;
    if (pieceToPlace == null || pieceToPlace.isUsed) return false;

    // Determine index of this piece in availablePieces
    final pieceIndex = state.availablePieces.indexWhere(
      (p) => p.instanceId == pieceToPlace.instanceId,
    );
    if (pieceIndex == -1) return false;

    if (!_engine.canPlacePiece(
      state.board,
      pieceToPlace.shape,
      anchorRow,
      anchorCol,
    )) {
      return false; // Invalid placement
    }

    // 1. Execute placement & row/col clearing
    final placement = _engine.placePiece(
      state.board,
      pieceToPlace.shape,
      anchorRow,
      anchorCol,
    );

    // 2. Mark piece as used
    final updatedPieces = List<BlockPiece>.from(state.availablePieces);
    updatedPieces[pieceIndex] = pieceToPlace.copyWith(isUsed: true);

    // 3. Update score
    final newScore = state.score + placement.totalScoreEarned;
    int newBestScore = state.bestScore;
    if (newScore > newBestScore) {
      newBestScore = newScore;
      try {
        await _statsStorage.recordBlockPuzzleScore(newScore);
      } catch (_) {}
    }

    // 4. Generate new set of 3 pieces if all 3 used
    List<BlockPiece> finalPieces = updatedPieces;
    final allUsed = updatedPieces.every((p) => p.isUsed);
    if (allUsed) {
      finalPieces = _engine.generateNewPieces();
    }

    // 5. Check Game Over
    final isOver = _engine.isGameOver(placement.newBoard, finalPieces);

    if (!isClosed) {
      emit(
        state.copyWith(
          board: placement.newBoard,
          availablePieces: finalPieces,
          selectedPieceIndex: () => null,
          hoverAnchor: () => null,
          score: newScore,
          bestScore: newBestScore,
          isGameOver: isOver,
          lastClearedIndices: placement.clearedCellIndices,
        ),
      );
    }

    return true;
  }

  /// Starts a fresh new game with an empty board and new pieces.
  void startNewGame() {
    final freshBoard = _engine.createEmptyBoard();
    final freshPieces = _engine.generateNewPieces();

    emit(
      BlockPuzzleState.initial(
        board: freshBoard,
        pieces: freshPieces,
        bestScore: state.bestScore,
      ),
    );
  }
}

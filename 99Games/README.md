# 99 Mini Games 🎮

A modular, production-ready Flutter mini-game application built with clean architecture, robust state management, and high testability. Designed to scale seamlessly to 99 distinct mini-games while sharing common infrastructure for routing, theme, audio/haptics settings, and persistent statistics.

---

## 🚀 Implemented Features

### 1. App Foundation & Navigation
- **Architecture**: Clean, modular structure separating **Domain** (pure Dart game engines), **Cubit** (immutable state management), **Presentation** (Material 3 UI), and **Core Storage**.
- **Dependency Injection**: Centralized service locator with `get_it` (`lib/di/injection.dart`).
- **Routing**: Declarative navigation via `go_router` (`lib/app/app_router.dart`).
- **Storage**: Centralized SharedPreferences abstractions (`AppPreferences` and `GameStatsStorage`).
- **Theming**: Tailored Material 3 palette with reactive live light and dark mode switching (`lib/app/app_theme.dart`).

### 2. Home Catalog Screen
- Responsive grid adapted for phones, foldables, tablets, and web.
- Visual distinction between playable games and future releases.
- Category filtering (`All`, `Classic`, `Puzzle`, `Brain & Memory`, `Word`).
- Direct navigation to playable games and informative coming-soon notifications for previews.
- Settings screen for appearance and audio/haptics toggles.

### 3. Tic-Tac-Toe (Game 1 — Fully Playable)
- **Game Modes**:
  - **Player vs AI**: Play against local AI with 3 distinct difficulty settings.
  - **Pass & Play**: Local 2-player mode on the same device.
- **AI Difficulties**:
  - `Easy`: Random selection of open cells.
  - `Medium`: Strategic heuristics (prioritizes immediate wins, blocks opponent threats, takes center).
  - `Hard`: Unbeatable Minimax algorithm (guaranteed optimal play, never loses).
- **Interactive UI**:
  - Responsive 3x3 board with smooth animations.
  - Animated cell markers with custom styling for X and O.
  - Glow and border highlights on the winning 3-in-a-row line.
  - Real-time turn and status banners.
  - Persistent scoreboard tracking wins, losses, and draws per mode/difficulty.
  - Score reset action with a confirmation dialog.

### 4. Number Slide (Game 2 — 15 Puzzle, Fully Playable)
- **Rules & Mechanics**:
  - Classic 4 × 4 board with 15 numbered tiles and one empty slot.
  - Solved configuration: 1 to 15 in ascending order with the empty slot in the bottom-right corner.
  - Only orthogonally adjacent tiles can slide into the empty slot.
- **Guaranteed Solvability**:
  - Scrambled using legal valid moves starting from the solved state (avoiding immediate reversals), ensuring mathematical solvability without UI blocking.
  - Evaluated with invariant mathematical solvability parity checking.
- **Timer & Persistence**:
  - Timer starts upon the first successful move (not on screen launch).
  - App lifecycle observer pauses/resumes timer smoothly on backgrounding/foregrounding.
  - Best score tracking persists fewer moves as primary criterion and faster time as tiebreaker.
- **UI & Controls**:
  - Visual distinction for movable tiles with comfortable touch targets.
  - Full-width modern gradient action button (Royal Blue in progress / Emerald when solved).
  - Confirmation dialog before discarding in-progress puzzles.
  - Victory modal celebrating completed puzzles with statistics.

### 5. Block Puzzle (Game 3 — Fully Playable)
- **Rules & Mechanics**:
  - Classic 10 × 10 grid block placement puzzle.
  - Three distinct block shapes provided simultaneously in the tray.
  - Shapes include single cells, 2-cell to 5-cell lines (horizontal & vertical), 2x2 and 3x3 squares, corner Ls, 3x3 L-shapes, T-shapes, and plus shapes.
  - Valid placements require all cells to fit inside the grid without overlapping existing blocks.
  - Placed pieces are consumed; once all 3 pieces are used, a fresh set of 3 pieces is generated.
- **Line Clearing & Scoring Engine**:
  - Completely filled rows and columns are cleared immediately.
  - Cleared cells belonging to both a completed row and column are deduplicated at intersections.
  - Scoring rules:
    - 1 point per placed piece cell.
    - 1 point per unique cleared cell.
    - Multi-line bonus: 10 extra points per additional completed line beyond the first in a single move.
- **Game Over Evaluation**:
  - Evaluates all remaining unplaced tray pieces across every possible grid coordinate.
  - Game continues as long as any available piece has at least one valid placement.
  - Declares game over only when *none* of the available pieces can fit anywhere.
- **Mobile-First Interactions**:
  - Dual control system: tap-to-select with tap-to-place board destination, plus drag-and-drop (`Draggable` / `DragTarget`).
  - Real-time placement preview with green (valid) / red (invalid) grid highlights.
  - Interactive tray with selected-piece scaling and visual glow.
  - High score persistence through `GameStatsStorage` using key `block_puzzle_best_score`.
  - Game-over dialog with final score, best score, new record badge, and Play Again / Home actions.

---

## 📁 Project Architecture

```
lib/
├── main.dart                                   # App entry point & dependency initialization
├── app/
│   ├── app.dart                                # MaterialApp.router root widget with reactive theme
│   ├── app_theme.dart                          # Material 3 light & dark themes
│   └── app_router.dart                         # GoRouter route definitions (/games/tic-tac-toe, /games/number-slide, /games/block-puzzle)
├── di/
│   └── injection.dart                          # GetIt dependency registration
├── core/
│   ├── storage/
│   │   ├── app_preferences.dart                # Theme & user settings interface + impl
│   │   ├── game_stats_storage.dart             # Game scores & best results persistence
│   │   └── storage_keys.dart                   # Centralized preference keys
│   ├── constants/
│   ├── utils/
│   └── widgets/
└── features/
    ├── home/
    │   ├── cubit/
    │   │   ├── home_cubit.dart                 # Catalog filtering & discovery logic
    │   │   └── home_state.dart                 # Catalog immutable state & GameInfo
    │   └── presentation/
    │       ├── home_screen.dart                # Responsive game catalog grid
    │       └── widgets/
    │           ├── category_filter_bar.dart    # Category filter chips
    │           └── game_card.dart              # Reusable game card
    ├── settings/
    │   └── presentation/
    │       └── settings_screen.dart            # Theme & sound preferences screen
    └── games/
        ├── tic_tac_toe/
        │   ├── domain/                         # Pure Dart game rules & Minimax AI
        │   ├── cubit/                          # TicTacToeCubit & TicTacToeState
        │   └── presentation/                   # TicTacToeScreen & board/cell widgets
        ├── number_slide/
        │   ├── domain/
        │   │   ├── number_slide_engine.dart    # Pure Dart 15-puzzle engine & solvable scrambler
        │   │   └── number_slide_models.dart    # TileCoordinate & position helpers
        │   ├── cubit/
        │   │   ├── number_slide_cubit.dart     # Moves, timer lifecycle & best result persistence
        │   │   └── number_slide_state.dart     # Immutable board, timer, moves & solved state
        │   └── presentation/
        │       ├── number_slide_screen.dart    # Main 15-puzzle game screen
        │       └── widgets/
        │           ├── number_slide_board.dart # 4x4 responsive board container
        │           ├── number_slide_tile.dart  # Interactive tile with movable styling
        │           ├── number_slide_stats_card.dart # Moves, timer & best record banner
        │           └── number_slide_victory_dialog.dart # Solved overlay dialog
        └── block_puzzle/
            ├── domain/
            │   ├── block_puzzle_engine.dart    # Pure Dart 10x10 placement, line clear & scoring engine
            │   └── block_puzzle_models.dart    # Coordinates, shapes, pieces & placement results
            ├── cubit/
            │   ├── block_puzzle_cubit.dart     # Immutable state transitions, tray & persistence
            │   └── block_puzzle_state.dart     # 100-cell board, tray pieces, hover & game over state
            └── presentation/
                ├── block_puzzle_screen.dart    # Block puzzle game screen & app bar actions
                └── widgets/
                    ├── block_puzzle_board.dart # 10x10 interactive board (tap & drag-and-drop)
                    ├── block_piece_widget.dart # Scaled shape render with cell highlights
                    ├── piece_tray.dart         # 3-piece tray selector with drag support
                    ├── block_puzzle_stats_card.dart # Live score & best score card
                    └── block_puzzle_game_over_dialog.dart # Game-over modal overlay

test/
├── widget_test.dart                            # Full app launch, Block Puzzle, Number Slide & Tic-Tac-Toe navigation smoke test
└── features/
    └── games/
        ├── tic_tac_toe/
        │   ├── tic_tac_toe_engine_test.dart    # Win conditions, draw, Minimax AI tests
        │   └── tic_tac_toe_cubit_test.dart     # Turn switching, score saving, resets
        ├── number_slide/
        │   ├── number_slide_engine_test.dart   # Move validation, scrambling, solvability checks
        │   └── number_slide_cubit_test.dart    # Moves, timer start/stop, victory persistence
        └── block_puzzle/
            ├── block_puzzle_engine_test.dart   # 10x10 placement, multi-line clear, intersection deduplication & scoring
            └── block_puzzle_cubit_test.dart    # Piece selection, hover, replenishment, game over & best score persistence
```

---

## 🛠️ Tech Stack & Dependencies

| Dependency | Purpose |
|------------|---------|
| `flutter_bloc: ^9.1.1` | Predictable state management using Cubit & immutable states |
| `go_router: ^17.5.0` | Declarative URL routing and deep linking |
| `get_it: ^9.3.0` | Inversion of control & dependency injection |
| `shared_preferences: ^2.5.6` | Lightweight key-value local storage |
| `equatable: ^3.0.0` | Value equality for immutable states and models |
| `bloc_test: ^10.0.0` | Unit testing utility for BLoC/Cubit |

---

## 🧪 Testing & Verification

Run static analysis:
```bash
flutter analyze
```

Run all unit and widget tests:
```bash
flutter test
```

Format code:
```bash
dart format lib test
```

---

## 📱 Running the Application

### Chrome / Web:
```bash
flutter run -d chrome
```

### macOS Desktop:
```bash
flutter run -d macos
```

### iOS / Android (with simulator or device connected):
```bash
flutter run
```

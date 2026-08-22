import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/dark_theme.dart';

enum PieceType { red, redKing, black, blackKing }

class CheckersPiece {
  final PieceType type;
  CheckersPiece({required this.type});

  bool get isRed => type == PieceType.red || type == PieceType.redKing;
  bool get isKing => type == PieceType.redKing || type == PieceType.blackKing;
}

class CheckersGameScreen extends StatefulWidget {
  final String gameMode; // 'pass_and_play', 'vs_ai', 'wager'
  final double wagerAmount;

  const CheckersGameScreen({
    super.key,
    this.gameMode = 'pass_and_play',
    this.wagerAmount = 0.0,
  });

  @override
  State<CheckersGameScreen> createState() => _CheckersGameScreenState();
}

class _CheckersGameScreenState extends State<CheckersGameScreen> {
  // 8x8 Board representation
  late List<List<CheckersPiece?>> _board;
  bool _isRedTurn = true; // Red moves first (bottom to top)
  Point<int>? _selectedPos;
  List<Point<int>> _validMoves = [];
  int _redScore = 0;
  int _blackScore = 0;
  String _gameStatus = 'Red\'s Turn';
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _initNewGame();
  }

  void _initNewGame() {
    _board = List.generate(8, (_) => List.generate(8, (_) => null));

    // Place Black pieces on top rows (0, 1, 2) on dark squares
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 8; c++) {
        if ((r + c) % 2 == 1) {
          _board[r][c] = CheckersPiece(type: PieceType.black);
        }
      }
    }

    // Place Red pieces on bottom rows (5, 6, 7) on dark squares
    for (int r = 5; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if ((r + c) % 2 == 1) {
          _board[r][c] = CheckersPiece(type: PieceType.red);
        }
      }
    }

    setState(() {
      _isRedTurn = true;
      _selectedPos = null;
      _validMoves = [];
      _redScore = 0;
      _blackScore = 0;
      _isGameOver = false;
      _gameStatus = widget.gameMode == 'vs_ai' ? 'Your Turn (Red)' : 'Red\'s Turn';
    });
  }

  void _onSquareTapped(int row, int col) {
    if (_isGameOver) return;
    if (widget.gameMode == 'vs_ai' && !_isRedTurn) return; // AI is thinking

    final piece = _board[row][col];

    // If tapping on own piece, select it
    if (piece != null && piece.isRed == _isRedTurn) {
      setState(() {
        _selectedPos = Point(row, col);
        _validMoves = _getValidMovesForPiece(row, col);
      });
      return;
    }

    // If a piece is already selected and tapping on a valid move
    if (_selectedPos != null && _validMoves.any((p) => p.x == row && p.y == col)) {
      _executeMove(_selectedPos!, Point(row, col));
    }
  }

  List<Point<int>> _getValidMovesForPiece(int r, int c) {
    final piece = _board[r][c];
    if (piece == null) return [];

    final moves = <Point<int>>[];
    final directions = <Point<int>>[];

    if (piece.isKing) {
      directions.addAll([const Point(-1, -1), const Point(-1, 1), const Point(1, -1), const Point(1, 1)]);
    } else if (piece.isRed) {
      directions.addAll([const Point(-1, -1), const Point(-1, 1)]); // Red moves UP (row decreases)
    } else {
      directions.addAll([const Point(1, -1), const Point(1, 1)]); // Black moves DOWN (row increases)
    }

    // 1. Check for single step moves
    for (final d in directions) {
      final nr = r + d.x;
      final nc = c + d.y;
      if (_isWithinBounds(nr, nc) && _board[nr][nc] == null) {
        moves.add(Point(nr, nc));
      }
    }

    // 2. Check for capture jumps
    for (final d in directions) {
      final midR = r + d.x;
      final midC = c + d.y;
      final jumpR = r + (d.x * 2);
      final jumpC = c + (d.y * 2);

      if (_isWithinBounds(jumpR, jumpC)) {
        final midPiece = _board[midR][midC];
        final destPiece = _board[jumpR][jumpC];
        if (midPiece != null && midPiece.isRed != piece.isRed && destPiece == null) {
          moves.add(Point(jumpR, jumpC));
        }
      }
    }

    return moves;
  }

  bool _isWithinBounds(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

  void _executeMove(Point<int> from, Point<int> to) {
    final piece = _board[from.x][from.y]!;
    bool isJump = (from.x - to.x).abs() == 2;

    _board[from.x][from.y] = null;

    // Handle Capture
    if (isJump) {
      final midR = (from.x + to.x) ~/ 2;
      final midC = (from.y + to.y) ~/ 2;
      _board[midR][midC] = null;
      if (piece.isRed) {
        _redScore++;
      } else {
        _blackScore++;
      }
    }

    // Handle King Promotion
    bool promoted = false;
    if (piece.isRed && to.x == 0 && !piece.isKing) {
      _board[to.x][to.y] = CheckersPiece(type: PieceType.redKing);
      promoted = true;
    } else if (!piece.isRed && to.x == 7 && !piece.isKing) {
      _board[to.x][to.y] = CheckersPiece(type: PieceType.blackKing);
      promoted = true;
    } else {
      _board[to.x][to.y] = piece;
    }

    // Check Win Condition
    if (_redScore >= 12 || _blackScore >= 12) {
      setState(() {
        _isGameOver = true;
        _gameStatus = _redScore >= 12 ? '🏆 Red Wins!' : '🏆 Black Wins!';
      });
      return;
    }

    // Switch Turn
    setState(() {
      _isRedTurn = !_isRedTurn;
      _selectedPos = null;
      _validMoves = [];
      _gameStatus = _isRedTurn
          ? (widget.gameMode == 'vs_ai' ? 'Your Turn (Red)' : 'Red\'s Turn')
          : (widget.gameMode == 'vs_ai' ? 'Kivo AI Thinking...' : 'Black\'s Turn');
    });

    // If vs AI and now Black's turn, trigger bot move
    if (widget.gameMode == 'vs_ai' && !_isRedTurn && !_isGameOver) {
      Future.delayed(const Duration(milliseconds: 600), _makeAiMove);
    }
  }

  void _makeAiMove() {
    if (_isGameOver) return;

    final allAiMoves = <Map<String, Point<int>>>[];

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = _board[r][c];
        if (p != null && !p.isRed) {
          final valid = _getValidMovesForPiece(r, c);
          for (final v in valid) {
            allAiMoves.add({'from': Point(r, c), 'to': v});
          }
        }
      }
    }

    if (allAiMoves.isEmpty) {
      setState(() {
        _isGameOver = true;
        _gameStatus = '🏆 Red Wins! (No valid AI moves)';
      });
      return;
    }

    // Prioritize capture jumps
    final jumps = allAiMoves.where((m) => (m['from']!.x - m['to']!.x).abs() == 2).toList();
    final chosenMove = jumps.isNotEmpty ? jumps[Random().nextInt(jumps.length)] : allAiMoves[Random().nextInt(allAiMoves.length)];

    _executeMove(chosenMove['from']!, chosenMove['to']!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          widget.gameMode == 'vs_ai' ? 'Checkers vs Kivo AI 🤖' : 'Jamaican Checkers 🇯🇲',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initNewGame,
            tooltip: 'Restart Game',
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Scoreboard & Turn Status
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: KivoDarkTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KivoDarkTheme.primaryEmerald.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Red Player Stats
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Color(0x66E53935), blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.gameMode == 'vs_ai' ? 'You (Red)' : 'Red Player', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('Captured: $_redScore', style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),

                // Status Center Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isRedTurn ? const Color(0x26E53935) : const Color(0x26FFD700),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _isRedTurn ? const Color(0xFFE53935) : const Color(0xFFFFD700)),
                  ),
                  child: Text(
                    _gameStatus,
                    style: TextStyle(
                      color: _isRedTurn ? const Color(0xFFFF8A80) : const Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

                // Black / AI Stats
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(widget.gameMode == 'vs_ai' ? 'Kivo Bot' : 'Black Player', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('Captured: $_blackScore', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF212121),
                        shape: BoxShape.circle,
                        border: Border.all(color: Color(0xFFFFD700), width: 1.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Interactive 8x8 Board
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155), width: 4),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                      ),
                      itemCount: 64,
                      itemBuilder: (context, index) {
                        final r = index ~/ 8;
                        final c = index % 8;
                        final isDarkSquare = (r + c) % 2 == 1;
                        final piece = _board[r][c];
                        final isSelected = _selectedPos?.x == r && _selectedPos?.y == c;
                        final isValidTarget = _validMoves.any((p) => p.x == r && p.y == c);

                        return GestureDetector(
                          onTap: () => _onSquareTapped(r, c),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDarkSquare
                                  ? (isSelected
                                      ? const Color(0xFF1E5128)
                                      : (isValidTarget ? const Color(0xFF00E676).withOpacity(0.3) : const Color(0xFF1B2430)))
                                  : const Color(0xFF334155),
                              border: isValidTarget ? Border.all(color: const Color(0xFF00E676), width: 2) : null,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (isValidTarget)
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00E676),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                if (piece != null) _buildPieceWidget(piece, isSelected),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Bottom Action Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _initNewGame,
                    icon: const Icon(Icons.refresh, size: 16, color: KivoDarkTheme.primaryEmerald),
                    label: const Text('Restart Board', style: TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: KivoDarkTheme.primaryEmerald),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.exit_to_app, size: 16, color: Colors.black),
                    label: const Text('Back to Arcade', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KivoDarkTheme.primaryEmerald,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieceWidget(CheckersPiece piece, bool isSelected) {
    final isRed = piece.isRed;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: isRed ? const Color(0xFFD32F2F) : const Color(0xFF212121),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? const Color(0xFF00E676) : (isRed ? const Color(0xFFFF8A80) : const Color(0xFFFFD700)),
          width: isSelected ? 3 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isRed ? const Color(0x66D32F2F) : Colors.black54,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: piece.isKing
            ? const Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 20)
            : Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
              ),
      ),
    );
  }
}

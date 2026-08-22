import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/dark_theme.dart';

enum LudoColor { red, green, yellow, blue }

class LudoToken {
  final int id;
  final LudoColor color;
  int step; // -1 = Home Base, 0..51 = Main Track, 52..57 = Home Column / Finished
  bool get isAtBase => step == -1;
  bool get isFinished => step == 57;

  LudoToken({required this.id, required this.color, this.step = -1});

  LudoToken copyWith({int? step}) => LudoToken(id: id, color: color, step: step ?? this.step);
}

class LudoGameScreen extends StatefulWidget {
  final String gameMode; // 'vs_ai', 'pass_and_play'

  const LudoGameScreen({
    super.key,
    this.gameMode = 'vs_ai',
  });

  @override
  State<LudoGameScreen> createState() => _LudoGameScreenState();
}

class _LudoGameScreenState extends State<LudoGameScreen> with SingleTickerProviderStateMixin {
  late Map<LudoColor, List<LudoToken>> _tokens;
  LudoColor _currentTurn = LudoColor.red;
  int _diceValue = 6;
  bool _hasRolled = false;
  bool _isRolling = false;
  String _statusMessage = 'Roll the dice to start your turn!';
  bool _isGameOver = false;

  late AnimationController _diceAnimController;

  @override
  void initState() {
    super.initState();
    _diceAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _initGame();
  }

  @override
  void dispose() {
    _diceAnimController.dispose();
    super.dispose();
  }

  void _initGame() {
    _tokens = {
      LudoColor.red: List.generate(4, (i) => LudoToken(id: i, color: LudoColor.red)),
      LudoColor.blue: List.generate(4, (i) => LudoToken(id: i, color: LudoColor.blue)),
      LudoColor.green: List.generate(4, (i) => LudoToken(id: i, color: LudoColor.green)),
      LudoColor.yellow: List.generate(4, (i) => LudoToken(id: i, color: LudoColor.yellow)),
    };
    _currentTurn = LudoColor.red;
    _diceValue = 6;
    _hasRolled = false;
    _isRolling = false;
    _isGameOver = false;
    _statusMessage = 'Your Turn (Red) — Tap the dice to roll!';
    setState(() {});
  }

  void _rollDice() {
    if (_hasRolled || _isRolling || _isGameOver) return;
    if (widget.gameMode == 'vs_ai' && _currentTurn != LudoColor.red) return;

    _executeRoll();
  }

  void _executeRoll() {
    setState(() {
      _isRolling = true;
    });
    _diceAnimController.forward(from: 0).then((_) {
      final roll = Random().nextInt(6) + 1;
      setState(() {
        _diceValue = roll;
        _isRolling = false;
        _hasRolled = true;
      });

      final currentTokens = _tokens[_currentTurn]!;
      final movableTokens = currentTokens.where((t) => _canMoveToken(t, roll)).toList();

      if (movableTokens.isEmpty) {
        // No moves possible -> pass turn
        setState(() {
          _statusMessage = 'Rolled $roll — No valid moves for ${_colorName(_currentTurn)}!';
        });
        Future.delayed(const Duration(milliseconds: 1000), _nextTurn);
      } else if (movableTokens.length == 1) {
        // Auto-move single eligible token
        setState(() {
          _statusMessage = 'Rolled $roll — Moving token automatically...';
        });
        Future.delayed(const Duration(milliseconds: 600), () => _moveToken(movableTokens.first, roll));
      } else {
        setState(() {
          _statusMessage = 'Rolled $roll — Select which token to advance!';
        });
      }
    });
  }

  bool _canMoveToken(LudoToken token, int roll) {
    if (token.isFinished) return false;
    if (token.isAtBase) return roll == 6; // Needs a 6 to enter track
    return (token.step + roll) <= 57; // Cannot overshoot home
  }

  void _onTokenTapped(LudoToken token) {
    if (!_hasRolled || _isRolling || _isGameOver) return;
    if (token.color != _currentTurn) return;
    if (!_canMoveToken(token, _diceValue)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 700),
          content: Text(token.isAtBase ? 'Needs a 6 to enter the board!' : 'Cannot move this token.'),
        ),
      );
      return;
    }

    _moveToken(token, _diceValue);
  }

  void _moveToken(LudoToken token, int roll) {
    setState(() {
      final list = _tokens[token.color]!;
      final idx = list.indexWhere((t) => t.id == token.id);
      if (idx == -1) return;

      int newStep;
      if (token.isAtBase) {
        newStep = 0; // Starts on track
      } else {
        newStep = token.step + roll;
      }

      list[idx] = token.copyWith(step: newStep);

      // Check capture on opponent (if on main track 0..51)
      if (newStep < 52) {
        _checkAndCaptureOpponents(token.color, newStep);
      }

      // Check Win
      if (list.every((t) => t.isFinished)) {
        _isGameOver = true;
        _statusMessage = '🏆 ${_colorName(token.color)} Wins the Game!';
        _showWinnerDialog(token.color);
        return;
      }
    });

    // Bonus roll on rolling a 6
    if (_diceValue == 6 && !_isGameOver) {
      setState(() {
        _hasRolled = false;
        _statusMessage = '${_colorName(_currentTurn)} rolled a 6! Earned a bonus roll!';
      });
      if (widget.gameMode == 'vs_ai' && _currentTurn != LudoColor.red) {
        Future.delayed(const Duration(milliseconds: 800), _executeRoll);
      }
    } else {
      Future.delayed(const Duration(milliseconds: 600), _nextTurn);
    }
  }

  void _checkAndCaptureOpponents(LudoColor myColor, int myStep) {
    // Check all other players' tokens
    for (final entry in _tokens.entries) {
      if (entry.key == myColor) continue;
      final oppTokens = entry.value;
      for (int i = 0; i < oppTokens.length; i++) {
        final oppToken = oppTokens[i];
        if (!oppToken.isAtBase && !oppToken.isFinished && oppToken.step == myStep) {
          // Send opponent back to base
          oppTokens[i] = oppToken.copyWith(step: -1);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: KivoDarkTheme.primaryEmerald,
              duration: const Duration(milliseconds: 1200),
              content: Text('💥 BOOM! ${_colorName(myColor)} captured ${_colorName(entry.key)}\'s token!'),
            ),
          );
        }
      }
    }
  }

  void _nextTurn() {
    if (_isGameOver) return;

    final colors = [LudoColor.red, LudoColor.blue, LudoColor.green, LudoColor.yellow];
    final nextIdx = (colors.indexOf(_currentTurn) + 1) % colors.length;

    setState(() {
      _currentTurn = colors[nextIdx];
      _hasRolled = false;
      _statusMessage = _currentTurn == LudoColor.red
          ? 'Your Turn (Red) — Tap dice to roll!'
          : '${_colorName(_currentTurn)} (AI) is rolling...';
    });

    if (widget.gameMode == 'vs_ai' && _currentTurn != LudoColor.red) {
      Future.delayed(const Duration(milliseconds: 800), _executeRoll);
    }
  }

  String _colorName(LudoColor c) {
    switch (c) {
      case LudoColor.red:
        return 'Red';
      case LudoColor.blue:
        return 'Blue';
      case LudoColor.green:
        return 'Green';
      case LudoColor.yellow:
        return 'Yellow';
    }
  }

  Color _colorValue(LudoColor c) {
    switch (c) {
      case LudoColor.red:
        return const Color(0xFFE53935);
      case LudoColor.blue:
        return const Color(0xFF1E88E5);
      case LudoColor.green:
        return const Color(0xFF43A047);
      case LudoColor.yellow:
        return const Color(0xFFFDD835);
    }
  }

  void _showWinnerDialog(LudoColor winner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: KivoDarkTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 28),
            const SizedBox(width: 10),
            Text('${_colorName(winner)} Champion! 🇯🇲', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          winner == LudoColor.red
              ? 'Congratulations! You successfully moved all 4 tokens home and won the Jamaican Ludo tournament!'
              : '${_colorName(winner)} took the match! Ready to roll again?',
          style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KivoDarkTheme.primaryEmerald,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _initGame();
            },
            child: const Text('Play Again 🎲', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Jamaican Ludo 🎲 🇯🇲', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initGame,
            tooltip: 'Restart Match',
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Player Turn Header Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: KivoDarkTheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _colorValue(_currentTurn),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: _colorValue(_currentTurn).withOpacity(0.6), blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Turn: ${_colorName(_currentTurn)}',
                      style: TextStyle(color: _colorValue(_currentTurn), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.gameMode == 'vs_ai' ? 'Vs 3 Kivo AI Bots' : '4-Player Pass & Play',
                    style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // 2. Caribbean Ludo Board View
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
                      BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // 15x15 Grid Layout
                      Column(
                        children: List.generate(15, (row) {
                          return Expanded(
                            child: Row(
                              children: List.generate(15, (col) {
                                return Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: _isBoardCell(row, col) ? Border.all(color: Colors.white12, width: 0.5) : null,
                                      color: _getCellColor(row, col),
                                    ),
                                    child: _buildCellTokens(row, col),
                                  ),
                                );
                              }),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Dice & Action Controls Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: KivoDarkTheme.surfaceElevated,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                // Interactive 3D Dice Box
                GestureToDismiss(
                  child: GestureDetector(
                    onTap: _rollDice,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _colorValue(_currentTurn), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: _colorValue(_currentTurn).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isRolling
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                            : Text(
                                '$_diceValue',
                                style: const TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.w900),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusMessage,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        !_hasRolled ? 'Tap the dice box to roll (1 to 6)' : 'Tap a highlighted token to move',
                        style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Board Coordinate Engine --- //
  
  static const List<Point<int>> _redPath = [
    Point(6,1), Point(6,2), Point(6,3), Point(6,4), Point(6,5),
    Point(5,6), Point(4,6), Point(3,6), Point(2,6), Point(1,6), Point(0,6),
    Point(0,7), Point(0,8),
    Point(1,8), Point(2,8), Point(3,8), Point(4,8), Point(5,8),
    Point(6,9), Point(6,10), Point(6,11), Point(6,12), Point(6,13), Point(6,14),
    Point(7,14), Point(8,14),
    Point(8,13), Point(8,12), Point(8,11), Point(8,10), Point(8,9),
    Point(9,8), Point(10,8), Point(11,8), Point(12,8), Point(13,8), Point(14,8),
    Point(14,7), Point(14,6),
    Point(13,6), Point(12,6), Point(11,6), Point(10,6), Point(9,6),
    Point(8,5), Point(8,4), Point(8,3), Point(8,2), Point(8,1), Point(8,0),
    Point(7,0)
  ];

  static const List<Point<int>> _redHome = [
    Point(7,1), Point(7,2), Point(7,3), Point(7,4), Point(7,5)
  ];

  Point<int> _rotate(Point<int> p, int turns) {
    int r = p.x;
    int c = p.y;
    for (int i = 0; i < turns; i++) {
      int newR = c;
      int newC = 14 - r;
      r = newR;
      c = newC;
    }
    return Point(r, c);
  }

  Point<int>? _getTokenPosition(LudoToken token) {
    if (token.isFinished) return Point(7,7); // Victory center
    if (token.isAtBase) return _getBasePosition(token);
    
    int turns = 0;
    if (token.color == LudoColor.green) turns = 1;
    if (token.color == LudoColor.yellow) turns = 2;
    if (token.color == LudoColor.blue) turns = 3;

    if (token.step < 51) {
      return _rotate(_redPath[token.step], turns);
    } else if (token.step >= 52 && token.step <= 56) {
      return _rotate(_redHome[token.step - 52], turns);
    }
    return Point(7,7);
  }

  Point<int> _getBasePosition(LudoToken token) {
    int rBase = 0, cBase = 0;
    if (token.color == LudoColor.red) { rBase = 2; cBase = 2; }
    if (token.color == LudoColor.green) { rBase = 2; cBase = 11; }
    if (token.color == LudoColor.yellow) { rBase = 11; cBase = 11; }
    if (token.color == LudoColor.blue) { rBase = 11; cBase = 2; }
    
    // Offset by token id for a 2x2 grid inside the 6x6 base
    int dr = token.id < 2 ? 0 : 1;
    int dc = token.id % 2 == 0 ? 0 : 1;
    return Point(rBase + dr, cBase + dc);
  }

  bool _isBoardCell(int row, int col) {
    // 3x3 center, plus 6x3 arms
    if (row >= 6 && row <= 8) return true;
    if (col >= 6 && col <= 8) return true;
    return false;
  }

  Color _getCellColor(int row, int col) {
    if (row >= 6 && row <= 8 && col >= 6 && col <= 8) return const Color(0xFFFFD700); // Center victory
    // Safe bases & home columns
    if (row == 6 && col == 1) return _colorValue(LudoColor.red).withOpacity(0.3);
    if (row == 1 && col == 8) return _colorValue(LudoColor.green).withOpacity(0.3);
    if (row == 8 && col == 13) return _colorValue(LudoColor.yellow).withOpacity(0.3);
    if (row == 13 && col == 6) return _colorValue(LudoColor.blue).withOpacity(0.3);
    
    // Home Columns
    if (row == 7 && col >= 1 && col <= 5) return _colorValue(LudoColor.red).withOpacity(0.2);
    if (col == 7 && row >= 1 && row <= 5) return _colorValue(LudoColor.green).withOpacity(0.2);
    if (row == 7 && col >= 9 && col <= 13) return _colorValue(LudoColor.yellow).withOpacity(0.2);
    if (col == 7 && row >= 9 && row <= 13) return _colorValue(LudoColor.blue).withOpacity(0.2);
    
    // Bases
    if (row < 6 && col < 6) return _colorValue(LudoColor.red).withOpacity(0.1);
    if (row < 6 && col > 8) return _colorValue(LudoColor.green).withOpacity(0.1);
    if (row > 8 && col > 8) return _colorValue(LudoColor.yellow).withOpacity(0.1);
    if (row > 8 && col < 6) return _colorValue(LudoColor.blue).withOpacity(0.1);

    return Colors.transparent;
  }

  Widget _buildCellTokens(int row, int col) {
    List<LudoToken> cellTokens = [];
    for (final tokens in _tokens.values) {
      for (final t in tokens) {
        if (_getTokenPosition(t) == Point(row, col)) {
          cellTokens.add(t);
        }
      }
    }
    if (cellTokens.isEmpty) return const SizedBox();

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: cellTokens.map((t) {
          final canMove = _hasRolled && t.color == _currentTurn && _canMoveToken(t, _diceValue);
          return GestureDetector(
            onTap: () => _onTokenTapped(t),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: _colorValue(t.color),
                shape: BoxShape.circle,
                border: Border.all(color: canMove ? const Color(0xFF00E676) : Colors.white, width: canMove ? 2 : 1),
                boxShadow: [
                  if (canMove) const BoxShadow(color: Color(0xFF00E676), blurRadius: 4, spreadRadius: 1),
                ],
              ),
              child: Center(
                child: Text(
                  '${t.id + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class GestureToDismiss extends StatelessWidget {
  final Widget child;
  const GestureToDismiss({super.key, required this.child});
  @override
  Widget build(BuildContext context) => child;
}

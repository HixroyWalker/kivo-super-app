import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/dark_theme.dart';

class SnakeAndLaddersGameScreen extends StatefulWidget {
  final String gameMode; // 'vs_ai', 'pass_and_play'

  const SnakeAndLaddersGameScreen({
    super.key,
    this.gameMode = 'vs_ai',
  });

  @override
  State<SnakeAndLaddersGameScreen> createState() => _SnakeAndLaddersGameScreenState();
}

class _SnakeAndLaddersGameScreenState extends State<SnakeAndLaddersGameScreen> with SingleTickerProviderStateMixin {
  int _player1Position = 0;
  int _player2Position = 0;
  bool _isPlayer1Turn = true;
  int _diceValue = 6;
  bool _isRolling = false;
  String _statusMessage = 'Tap dice to roll!';
  bool _isGameOver = false;

  late AnimationController _diceAnimController;

  final Map<int, int> ladders = {
    4: 14,
    9: 31,
    21: 42,
    28: 84,
    51: 67,
    71: 91,
    80: 100,
  };

  final Map<int, int> snakes = {
    16: 6,
    47: 26,
    49: 11,
    56: 53,
    62: 19,
    64: 60,
    87: 24,
    93: 73,
    95: 75,
    98: 78,
  };

  @override
  void initState() {
    super.initState();
    _diceAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _diceAnimController.dispose();
    super.dispose();
  }

  void _initGame() {
    setState(() {
      _player1Position = 0;
      _player2Position = 0;
      _isPlayer1Turn = true;
      _diceValue = 6;
      _isRolling = false;
      _isGameOver = false;
      _statusMessage = 'Your Turn (Red) — Tap dice to roll!';
    });
  }

  void _rollDice() {
    if (_isRolling || _isGameOver) return;
    if (widget.gameMode == 'vs_ai' && !_isPlayer1Turn) return;

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
      });

      _movePlayer(roll);
    });
  }

  void _movePlayer(int roll) {
    setState(() {
      int pos = _isPlayer1Turn ? _player1Position : _player2Position;
      
      if (pos == 0) {
        if (roll == 6) {
          pos = 1;
          _statusMessage = '${_playerName()} rolled a 6 and enters the board!';
        } else {
          _statusMessage = '${_playerName()} rolled $roll. Needs a 6 to start.';
          Future.delayed(const Duration(milliseconds: 1000), _nextTurn);
          return;
        }
      } else {
        if (pos + roll <= 100) {
          pos += roll;
          _statusMessage = '${_playerName()} rolled $roll and moved to $pos.';
        } else {
          _statusMessage = '${_playerName()} rolled $roll. Need exact roll to win!';
          Future.delayed(const Duration(milliseconds: 1000), _nextTurn);
          return;
        }
      }

      _updatePosition(pos);
      _checkSnakesAndLadders(pos);
    });
  }

  void _updatePosition(int pos) {
    if (_isPlayer1Turn) {
      _player1Position = pos;
    } else {
      _player2Position = pos;
    }
  }

  void _checkSnakesAndLadders(int pos) {
    if (ladders.containsKey(pos)) {
      final newPos = ladders[pos]!;
      Future.delayed(const Duration(milliseconds: 600), () {
        setState(() {
          _statusMessage = 'Awesome! climbed a ladder to $newPos';
          _updatePosition(newPos);
          _checkWin(newPos);
        });
      });
    } else if (snakes.containsKey(pos)) {
      final newPos = snakes[pos]!;
      Future.delayed(const Duration(milliseconds: 600), () {
        setState(() {
          _statusMessage = 'Oh no! Slid down a snake to $newPos';
          _updatePosition(newPos);
          _checkWin(newPos);
        });
      });
    } else {
      _checkWin(pos);
    }
  }

  void _checkWin(int pos) {
    if (pos == 100) {
      _isGameOver = true;
      _statusMessage = '🏆 ${_playerName()} Wins the Game!';
      _showWinnerDialog(_isPlayer1Turn);
    } else {
      if (_diceValue == 6) {
         setState(() {
            _statusMessage = '${_playerName()} gets another roll!';
         });
         if (widget.gameMode == 'vs_ai' && !_isPlayer1Turn) {
            Future.delayed(const Duration(milliseconds: 1000), _executeRoll);
         }
      } else {
        Future.delayed(const Duration(milliseconds: 800), _nextTurn);
      }
    }
  }

  void _nextTurn() {
    if (_isGameOver) return;
    setState(() {
      _isPlayer1Turn = !_isPlayer1Turn;
      if (_isPlayer1Turn) {
        _statusMessage = 'Your Turn (Red) — Tap dice to roll!';
      } else {
        _statusMessage = widget.gameMode == 'vs_ai' ? 'Buju (AI) is rolling...' : 'Player 2 Turn (Blue) — Tap dice!';
      }
    });

    if (widget.gameMode == 'vs_ai' && !_isPlayer1Turn) {
      Future.delayed(const Duration(milliseconds: 800), _executeRoll);
    }
  }

  String _playerName() {
    if (_isPlayer1Turn) return 'Player 1 (Red)';
    return widget.gameMode == 'vs_ai' ? 'Buju (AI)' : 'Player 2 (Blue)';
  }

  void _showWinnerDialog(bool player1Won) {
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
            Text(player1Won ? 'You Win! 🇯🇲' : 'Blue Wins! 🇯🇲', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          player1Won ? 'Congratulations! You reached 100 first!' : 'The AI beat you to 100!',
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
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text('Snakes & Ladders 🐍 🇯🇲', style: TextStyle(fontWeight: FontWeight.bold)),
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: KivoDarkTheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 16, height: 16, decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    const Text('Red: P1', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                  child: Text(widget.gameMode == 'vs_ai' ? 'Vs Buju AI' : 'Pass & Play', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: [
                    const Text('Blue: P2', style: TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(width: 16, height: 16, decoration: const BoxDecoration(color: Color(0xFF1E88E5), shape: BoxShape.circle)),
                  ],
                ),
              ],
            ),
          ),
          
          // Board
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4332), // Jungle green
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD700), width: 3),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Stack(
                    children: [
                       // 10x10 Grid
                       Column(
                         children: List.generate(10, (row) {
                           return Expanded(
                             child: Row(
                               children: List.generate(10, (col) {
                                 int cellNumber = _getCellNumber(row, col);
                                 bool isLight = (row + col) % 2 == 0;
                                 return Expanded(
                                   child: Container(
                                     decoration: BoxDecoration(
                                        color: isLight ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.2),
                                        border: Border.all(color: Colors.black.withOpacity(0.3), width: 0.5),
                                     ),
                                     child: Stack(
                                       children: [
                                          Positioned(
                                            top: 2, left: 4,
                                            child: Text('$cellNumber', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                          if (ladders.containsKey(cellNumber))
                                            const Center(child: Icon(Icons.trending_up, color: Colors.brown, size: 20)),
                                          if (snakes.containsKey(cellNumber))
                                            const Center(child: Icon(Icons.trending_down, color: Colors.redAccent, size: 20)),
                                          if (_player1Position == cellNumber)
                                            Align(
                                              alignment: Alignment.bottomLeft,
                                              child: Padding(
                                                padding: const EdgeInsets.all(4.0),
                                                child: Container(width: 14, height: 14, decoration: BoxDecoration(color: const Color(0xFFE53935), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5))),
                                              ),
                                            ),
                                          if (_player2Position == cellNumber)
                                            Align(
                                              alignment: Alignment.bottomRight,
                                              child: Padding(
                                                padding: const EdgeInsets.all(4.0),
                                                child: Container(width: 14, height: 14, decoration: BoxDecoration(color: const Color(0xFF1E88E5), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5))),
                                              ),
                                            ),
                                       ],
                                     ),
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

          // Dice Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: KivoDarkTheme.surfaceElevated,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _rollDice,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _isPlayer1Turn ? const Color(0xFFE53935) : const Color(0xFF1E88E5), width: 3),
                      boxShadow: [
                         BoxShadow(color: (_isPlayer1Turn ? const Color(0xFFE53935) : const Color(0xFF1E88E5)).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: _isRolling
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                          : Text('$_diceValue', style: const TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_statusMessage, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      const Text('First to reach 100 exactly wins!', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
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

  int _getCellNumber(int row, int col) {
    int logicalRow = 9 - row; // 0 at bottom, 9 at top
    if (logicalRow % 2 == 0) {
      // Even rows go left to right (1..10)
      return (logicalRow * 10) + col + 1;
    } else {
      // Odd rows go right to left (20..11)
      return (logicalRow * 10) + (9 - col) + 1;
    }
  }
}

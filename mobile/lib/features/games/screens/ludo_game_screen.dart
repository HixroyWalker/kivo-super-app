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
                      // Quadrants Layout
                      Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                _buildBaseQuadrant(LudoColor.red, 'Red (You)'),
                                _buildTrackColumn(isVertical: true, isTop: true),
                                _buildBaseQuadrant(LudoColor.green, 'Green (AI)'),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              _buildTrackRow(isLeft: true),
                              _buildCenterVictoryHome(),
                              _buildTrackRow(isLeft: false),
                            ],
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                _buildBaseQuadrant(LudoColor.blue, 'Blue (AI)'),
                                _buildTrackColumn(isVertical: true, isTop: false),
                                _buildBaseQuadrant(LudoColor.yellow, 'Yellow (AI)'),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildBaseQuadrant(LudoColor color, String label) {
    final tokens = _tokens[color]!;
    final baseTokens = tokens.where((t) => t.isAtBase).toList();

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _colorValue(color).withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _colorValue(color), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: _colorValue(color), fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tokens.map((token) {
                final isTurn = token.color == _currentTurn;
                final canMove = _hasRolled && _canMoveToken(token, _diceValue);
                return GestureDetector(
                  onTap: () => _onTokenTapped(token),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: token.isAtBase ? _colorValue(color) : (token.isFinished ? Colors.white : _colorValue(color).withOpacity(0.5)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: canMove ? const Color(0xFF00E676) : Colors.white,
                        width: canMove ? 2.5 : 1,
                      ),
                      boxShadow: [
                        if (canMove)
                          const BoxShadow(color: Color(0xFF00E676), blurRadius: 6, spreadRadius: 1),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        token.isFinished ? '★' : '${token.id + 1}',
                        style: TextStyle(color: token.isFinished ? Colors.black : Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackColumn({required bool isVertical, required bool isTop}) {
    return Container(
      width: 44,
      color: const Color(0xFF334155),
      child: const Center(
        child: Icon(Icons.arrow_upward, color: Colors.white24, size: 16),
      ),
    );
  }

  Widget _buildTrackRow({required bool isLeft}) {
    return Container(
      width: 100,
      height: 44,
      color: const Color(0xFF334155),
      child: const Center(
        child: Icon(Icons.arrow_forward, color: Colors.white24, size: 16),
      ),
    );
  }

  Widget _buildCenterVictoryHome() {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFFFD700),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.star, color: Colors.black, size: 28),
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

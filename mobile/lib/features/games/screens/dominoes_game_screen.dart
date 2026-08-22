import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/dark_theme.dart';

class DominoTile {
  final int left;
  final int right;
  final String id;

  DominoTile({required this.left, required this.right, required this.id});

  bool get isDouble => left == right;
  int get totalPips => left + right;

  DominoTile flipped() => DominoTile(left: right, right: left, id: id);
}

class PlayedDomino {
  final DominoTile tile;
  final Offset position;
  final double angle;
  PlayedDomino({required this.tile, required this.position, required this.angle});
}

class DominoesGameScreen extends StatefulWidget {
  final String gameMode; // 'vs_ai', 'pass_and_play'

  const DominoesGameScreen({
    super.key,
    this.gameMode = 'vs_ai',
  });

  @override
  State<DominoesGameScreen> createState() => _DominoesGameScreenState();
}

class _DominoesGameScreenState extends State<DominoesGameScreen> {
  late List<DominoTile> _boneyard;
  late List<DominoTile> _playerHand;
  late List<DominoTile> _opponentHand;
  List<PlayedDomino> _playedTiles = [];

  Offset _leftEndPos = const Offset(2000, 2000);
  int _leftEndDir = 2; // 0: Right, 1: Down, 2: Left, 3: Up
  Offset _rightEndPos = const Offset(2000, 2000);
  int _rightEndDir = 0; // 0: Right, 1: Down, 2: Left, 3: Up

  final TransformationController _transformCtrl = TransformationController();

  int _openLeftEnd = -1;
  int _openRightEnd = -1;
  bool _isPlayerTurn = true;
  bool _isGameOver = false;
  String _gameMessage = 'Select a domino to pose';

  int _playerRoundsWon = 0;
  int _opponentRoundsWon = 0;
  DominoTile? _selectedTile;

  @override
  void initState() {
    super.initState();
    _startNewRound();
  }

  void _startNewRound() {
    // 1. Generate standard 28 double-six dominoes
    final allTiles = <DominoTile>[];
    int tileId = 1;
    for (int i = 0; i <= 6; i++) {
      for (int j = i; j <= 6; j++) {
        allTiles.add(DominoTile(left: i, right: j, id: 'd_${tileId++}'));
      }
    }
    allTiles.shuffle(Random());

    // 2. Deal 7 tiles to player, 7 to opponent, 14 to boneyard
    _playerHand = allTiles.sublist(0, 7);
    _opponentHand = allTiles.sublist(7, 14);
    _boneyard = allTiles.sublist(14);
    _playedTiles = [];
    _leftEndPos = const Offset(2000, 2000);
    _rightEndPos = const Offset(2000, 2000);
    _leftEndDir = 2;
    _rightEndDir = 0;
    _openLeftEnd = -1;
    _openRightEnd = -1;
    _isGameOver = false;
    _selectedTile = null;

    // 3. Determine first pose: player with Double-6 or highest double
    DominoTile? highestPlayerDouble = _getHighestDouble(_playerHand);
    DominoTile? highestOppDouble = _getHighestDouble(_opponentHand);

    if (highestPlayerDouble != null && (highestOppDouble == null || highestPlayerDouble.left >= highestOppDouble.left)) {
      _isPlayerTurn = true;
      _gameMessage = 'Your Turn! Pose [${highestPlayerDouble.left}|${highestPlayerDouble.right}] or any bone';
    } else if (highestOppDouble != null) {
      _isPlayerTurn = false;
      _gameMessage = 'Opponent is posing...';
      Future.delayed(const Duration(milliseconds: 700), _makeOpponentMove);
    } else {
      _isPlayerTurn = true;
      _gameMessage = 'Your Turn! Pose first bone';
    }

    setState(() {});
  }

  DominoTile? _getHighestDouble(List<DominoTile> hand) {
    final doubles = hand.where((t) => t.isDouble).toList();
    if (doubles.isEmpty) return null;
    doubles.sort((a, b) => b.left.compareTo(a.left));
    return doubles.first;
  }

  bool _canPlayTile(DominoTile tile) {
    if (_playedTiles.isEmpty) return true;
    return tile.left == _openLeftEnd ||
        tile.right == _openLeftEnd ||
        tile.left == _openRightEnd ||
        tile.right == _openRightEnd;
  }

  void _onTileTapped(DominoTile tile) {
    if (!_isPlayerTurn || _isGameOver) return;

    if (_playedTiles.isEmpty) {
      // First pose
      _playTileOnBoard(tile, isLeftEnd: true);
      return;
    }

    final fitsLeft = tile.left == _openLeftEnd || tile.right == _openLeftEnd;
    final fitsRight = tile.left == _openRightEnd || tile.right == _openRightEnd;

    if (!fitsLeft && !fitsRight) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 900),
          content: Text('Cannot play [${tile.left}|${tile.right}]. Ends are $_openLeftEnd and $_openRightEnd.'),
        ),
      );
      return;
    }

    if (fitsLeft && fitsRight && _openLeftEnd != _openRightEnd) {
      // Prompt user to pick which end
      _showEndChoiceDialog(tile);
    } else if (fitsLeft) {
      _playTileOnBoard(tile, isLeftEnd: true);
    } else {
      _playTileOnBoard(tile, isLeftEnd: false);
    }
  }

  void _showEndChoiceDialog(DominoTile tile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KivoDarkTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Choose Side to Play', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Play [${tile.left}|${tile.right}] on Left ($_openLeftEnd) or Right ($_openRightEnd)?', style: const TextStyle(color: KivoDarkTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _playTileOnBoard(tile, isLeftEnd: true);
            },
            child: Text('Play on Left ($_openLeftEnd)', style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: KivoDarkTheme.primaryEmerald, foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(ctx);
              _playTileOnBoard(tile, isLeftEnd: false);
            },
            child: Text('Play on Right ($_openRightEnd)', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _placeTile(DominoTile orientedTile, bool isLeftEnd) {
    if (_playedTiles.isEmpty) {
      _playedTiles.add(PlayedDomino(
        tile: orientedTile,
        position: const Offset(2000, 2000),
        angle: orientedTile.isDouble ? 0.0 : pi / 2,
      ));
      _leftEndPos = const Offset(2000, 2000);
      _rightEndPos = const Offset(2000, 2000);
      _leftEndDir = 2;
      _rightEndDir = 0;
      _openLeftEnd = orientedTile.left;
      _openRightEnd = orientedTile.right;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final size = MediaQuery.of(context).size;
        _transformCtrl.value = Matrix4.identity()
          ..translate(-2000.0 + size.width / 2, -2000.0 + size.height / 3);
      });
      return;
    }

    bool isDouble = orientedTile.isDouble;
    
    if (isLeftEnd) {
      final prevTileObj = _playedTiles.lastWhere((p) => p.position == _leftEndPos);
      bool prevIsDouble = prevTileObj.tile.isDouble;

      double prevDist = prevIsDouble ? 22.0 : 38.0;
      double newDist = isDouble ? 22.0 : 38.0;

      if (_leftEndDir == 2 && _leftEndPos.dx < 1200) _leftEndDir = 3;
      else if (_leftEndDir == 3 && _leftEndPos.dy < 1200) _leftEndDir = 0;
      else if (_leftEndDir == 0 && _leftEndPos.dx > 2800) _leftEndDir = 1;
      else if (_leftEndDir == 1 && _leftEndPos.dy > 2800) _leftEndDir = 2;

      double step = prevDist + newDist + 4.0;
      Offset newPos = _leftEndPos;
      if (_leftEndDir == 0) newPos += Offset(step, 0);
      else if (_leftEndDir == 1) newPos += Offset(0, step);
      else if (_leftEndDir == 2) newPos += Offset(-step, 0);
      else if (_leftEndDir == 3) newPos += Offset(0, -step);

      double angle = 0.0;
      if (_leftEndDir == 0 || _leftEndDir == 2) angle = isDouble ? 0.0 : pi / 2;
      else if (_leftEndDir == 1 || _leftEndDir == 3) angle = isDouble ? pi / 2 : 0.0;

      _playedTiles.add(PlayedDomino(tile: orientedTile, position: newPos, angle: angle));
      _leftEndPos = newPos;
      _openLeftEnd = orientedTile.left;
    } else {
      final prevTileObj = _playedTiles.lastWhere((p) => p.position == _rightEndPos);
      bool prevIsDouble = prevTileObj.tile.isDouble;

      double prevDist = prevIsDouble ? 22.0 : 38.0;
      double newDist = isDouble ? 22.0 : 38.0;

      if (_rightEndDir == 0 && _rightEndPos.dx > 2800) _rightEndDir = 1;
      else if (_rightEndDir == 1 && _rightEndPos.dy > 2800) _rightEndDir = 2;
      else if (_rightEndDir == 2 && _rightEndPos.dx < 1200) _rightEndDir = 3;
      else if (_rightEndDir == 3 && _rightEndPos.dy < 1200) _rightEndDir = 0;

      double step = prevDist + newDist + 4.0;
      Offset newPos = _rightEndPos;
      if (_rightEndDir == 0) newPos += Offset(step, 0);
      else if (_rightEndDir == 1) newPos += Offset(0, step);
      else if (_rightEndDir == 2) newPos += Offset(-step, 0);
      else if (_rightEndDir == 3) newPos += Offset(0, -step);

      double angle = 0.0;
      if (_rightEndDir == 0 || _rightEndDir == 2) angle = isDouble ? 0.0 : pi / 2;
      else if (_rightEndDir == 1 || _rightEndDir == 3) angle = isDouble ? pi / 2 : 0.0;

      _playedTiles.add(PlayedDomino(tile: orientedTile, position: newPos, angle: angle));
      _rightEndPos = newPos;
      _openRightEnd = orientedTile.right;
    }
  }

  void _playTileOnBoard(DominoTile tile, {required bool isLeftEnd}) {
    _playerHand.removeWhere((t) => t.id == tile.id);

    DominoTile orientedTile = tile;

    if (_playedTiles.isEmpty) {
      orientedTile = tile;
      _placeTile(orientedTile, true);
    } else if (isLeftEnd) {
      if (tile.right == _openLeftEnd) {
        orientedTile = tile;
      } else {
        orientedTile = tile.flipped();
      }
      _placeTile(orientedTile, true);
    } else {
      if (tile.left == _openRightEnd) {
        orientedTile = tile;
      } else {
        orientedTile = tile.flipped();
      }
      _placeTile(orientedTile, false);
    }

    // Check Win
    if (_playerHand.isEmpty) {
      setState(() {
        _playerRoundsWon++;
        _isGameOver = true;
        _gameMessage = '💥 DOMINO! You Won This Round!';
      });
      _showRoundWinModal(isPlayerWin: true);
      return;
    }

    // Check Block Condition
    if (_isGameBlocked()) {
      _handleBlockedGame();
      return;
    }

    // Switch Turn
    setState(() {
      _isPlayerTurn = false;
      _gameMessage = widget.gameMode == 'vs_ai' ? 'Buju (AI) is thinking...' : 'Opponent\'s Turn';
    });

    if (widget.gameMode == 'vs_ai' && !_isGameOver) {
      Future.delayed(const Duration(milliseconds: 700), _makeOpponentMove);
    }
  }

  void _makeOpponentMove() {
    if (_isGameOver) return;

    if (_playedTiles.isEmpty) {
      final highest = _getHighestDouble(_opponentHand) ?? _opponentHand.first;
      _opponentHand.removeWhere((t) => t.id == highest.id);
      _placeTile(highest, true);
    } else {
      DominoTile? playableTile;
      bool playOnLeft = true;

      for (final tile in _opponentHand) {
        if (tile.left == _openLeftEnd || tile.right == _openLeftEnd) {
          playableTile = tile;
          playOnLeft = true;
          break;
        } else if (tile.left == _openRightEnd || tile.right == _openRightEnd) {
          playableTile = tile;
          playOnLeft = false;
          break;
        }
      }

      if (playableTile != null) {
        _opponentHand.removeWhere((t) => t.id == playableTile!.id);
        DominoTile orientedTile = playableTile;

        if (playOnLeft) {
          if (playableTile.right == _openLeftEnd) {
            orientedTile = playableTile;
          } else {
            orientedTile = playableTile.flipped();
          }
          _placeTile(orientedTile, true);
        } else {
          if (playableTile.left == _openRightEnd) {
            orientedTile = playableTile;
          } else {
            orientedTile = playableTile.flipped();
          }
          _placeTile(orientedTile, false);
        }
      } else {
        // Opponent must knock/pass
        if (_boneyard.isNotEmpty) {
          final drawn = _boneyard.removeLast();
          _opponentHand.add(drawn);
        }
      }
    }

    // Check Opponent Win
    if (_opponentHand.isEmpty) {
      setState(() {
        _opponentRoundsWon++;
        _isGameOver = true;
        _gameMessage = 'Opponent Dominoed!';
      });
      _showRoundWinModal(isPlayerWin: false);
      return;
    }

    if (_isGameBlocked()) {
      _handleBlockedGame();
      return;
    }

    setState(() {
      _isPlayerTurn = true;
      _gameMessage = 'Your Turn! (Ends: [$_openLeftEnd] & [$_openRightEnd])';
    });
  }

  void _playerKnockPass() {
    if (!_isPlayerTurn || _isGameOver) return;

    final hasPlayable = _playerHand.any((t) => _canPlayTile(t));
    if (hasPlayable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have playable dominoes in your hand!')),
      );
      return;
    }

    if (_boneyard.isNotEmpty) {
      setState(() {
        final drawn = _boneyard.removeLast();
        _playerHand.add(drawn);
        _gameMessage = 'Drew [${drawn.left}|${drawn.right}] from Pack';
      });
      return;
    }

    // Knock / Pass turn
    setState(() {
      _isPlayerTurn = false;
      _gameMessage = 'You Knocked! Opponent\'s Turn';
    });

    if (widget.gameMode == 'vs_ai') {
      Future.delayed(const Duration(milliseconds: 700), _makeOpponentMove);
    }
  }

  bool _isGameBlocked() {
    if (_playedTiles.isEmpty) return false;
    final playerHasMove = _playerHand.any((t) => _canPlayTile(t));
    final oppHasMove = _opponentHand.any((t) => _canPlayTile(t));
    return !playerHasMove && !oppHasMove && _boneyard.isEmpty;
  }

  void _handleBlockedGame() {
    final playerTotal = _playerHand.fold<int>(0, (s, t) => s + t.totalPips);
    final oppTotal = _opponentHand.fold<int>(0, (s, t) => s + t.totalPips);

    bool playerWon = playerTotal < oppTotal;
    if (playerWon) {
      _playerRoundsWon++;
    } else {
      _opponentRoundsWon++;
    }

    setState(() {
      _isGameOver = true;
      _gameMessage = '🔒 BLOCKED GAME! (You: $playerTotal pips, Opponent: $oppTotal pips)';
    });

    _showRoundWinModal(isPlayerWin: playerWon, isBlocked: true);
  }

  void _showRoundWinModal({required bool isPlayerWin, bool isBlocked = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: KivoDarkTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isPlayerWin ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                color: isPlayerWin ? const Color(0xFFFFD700) : KivoDarkTheme.accentRose, size: 28),
            const SizedBox(width: 10),
            Text(
              isPlayerWin ? (isBlocked ? 'Lock Game Win! 🔒' : 'DOMINO! 💥') : 'Opponent Won Round',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPlayerWin
                  ? 'Congratulations! You won the hand in authentic Jamaican style.'
                  : 'Opponent took this round. Ready for revenge?',
              style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: KivoDarkTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: KivoDarkTheme.primaryEmerald.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('YOU', style: TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('$_playerRoundsWon Wins', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Text('VS', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
                  Column(
                    children: [
                      const Text('OPPONENT', style: TextStyle(color: KivoDarkTheme.accentRose, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('$_opponentRoundsWon Wins', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            if (_playerRoundsWon >= 6) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('🏆 SIX LOVE 6-0 CHAMPION 🇯🇲', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ],
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
              _startNewRound();
            },
            child: const Text('Play Next Hand 🁓', style: TextStyle(fontWeight: FontWeight.bold)),
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
        title: const Text('Jamaican Dominoes 🁓 🇯🇲', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startNewRound,
            tooltip: 'Reshuffle & New Hand',
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Match Header Scoreboard
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: KivoDarkTheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: KivoDarkTheme.accentRose,
                      child: Icon(Icons.smart_toy, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text('Buju (AI): ${_opponentHand.length} tiles', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: KivoDarkTheme.primaryEmerald.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KivoDarkTheme.primaryEmerald),
                  ),
                  child: Text('Score: $_playerRoundsWon - $_opponentRoundsWon', style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                Row(
                  children: [
                    Text('Pack: ${_boneyard.length}', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                    const SizedBox(width: 8),
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: KivoDarkTheme.primaryEmerald,
                      child: Icon(Icons.person, size: 16, color: Colors.black),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Caribbean Domino Table (Felt & Wood)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4332), // Emerald felt table
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF8D6E63), width: 6), // Mahogany wood rim
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
              child: Stack(
                children: [
                  // Center Island watermark
                  const Center(
                    child: Opacity(
                      opacity: 0.08,
                      child: Icon(Icons.sports_esports, size: 180, color: Colors.white),
                    ),
                  ),

                  // Open Ends Indicators
                  if (_playedTiles.isNotEmpty)
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                            child: Text('Left End: [$_openLeftEnd]', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                            child: Text('Right End: [$_openRightEnd]', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                    ),

                  // Table Chain 2D View
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: InteractiveViewer(
                      transformationController: _transformCtrl,
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(2000),
                      minScale: 0.1,
                      maxScale: 2.0,
                      child: SizedBox(
                        width: 4000,
                        height: 4000,
                        child: Stack(
                          children: [
                            if (_playedTiles.isEmpty)
                              Positioned(
                                left: 2000 - 80,
                                top: 2000 - 20,
                                child: const Text('Pose First Domino', style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            for (final pd in _playedTiles)
                              Positioned(
                                left: pd.position.dx - 22,
                                top: pd.position.dy - 38,
                                child: Transform.rotate(
                                  angle: pd.angle,
                                  child: _buildTableTile(pd.tile),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Game Status Pill
                  Positioned(
                    bottom: 12,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _isPlayerTurn ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.accentAmber),
                      ),
                      child: Text(
                        _gameMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isPlayerTurn ? KivoDarkTheme.primaryEmerald : const Color(0xFFFFD700),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Player's Hand Tray (7 Bones)
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            decoration: const BoxDecoration(
              color: KivoDarkTheme.surfaceElevated,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Your Dominoes (Hand):', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    if (_isPlayerTurn)
                      TextButton.icon(
                        onPressed: _playerKnockPass,
                        icon: const Icon(Icons.front_hand, size: 14, color: Color(0xFFFFD700)),
                        label: Text(_boneyard.isNotEmpty ? 'Draw from Pack' : 'KNOCK / PASS', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 80,
                  child: _playerHand.isEmpty
                      ? const Center(child: Text('Hand empty!', style: TextStyle(color: KivoDarkTheme.primaryEmerald)))
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _playerHand.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final tile = _playerHand[idx];
                            final canPlay = _canPlayTile(tile);
                            return GestureDetector(
                              onTap: () => _onTileTapped(tile),
                              child: _buildHandTile(tile, canPlay),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tile rendering on the table
  Widget _buildTableTile(DominoTile tile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 44,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6), // Ivory domino surface
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black87, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 2))],
      ),
      child: Column(
        children: [
          Expanded(child: Center(child: _buildPipGrid(tile.left))),
          Container(height: 1.5, color: Colors.black87), // Center divider
          Expanded(child: Center(child: _buildPipGrid(tile.right))),
        ],
      ),
    );
  }

  // Tile rendering in player hand
  Widget _buildHandTile(DominoTile tile, bool canPlay) {
    return Container(
      width: 44,
      height: 76,
      decoration: BoxDecoration(
        color: canPlay ? const Color(0xFFFFFDE7) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: canPlay ? KivoDarkTheme.primaryEmerald : Colors.black45,
          width: canPlay ? 2 : 1,
        ),
        boxShadow: [
          if (canPlay)
            BoxShadow(color: KivoDarkTheme.primaryEmerald.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Expanded(child: Center(child: _buildPipGrid(tile.left))),
          Container(height: 1.5, color: Colors.black87),
          Expanded(child: Center(child: _buildPipGrid(tile.right))),
        ],
      ),
    );
  }

  // Visual domino pips (dots)
  Widget _buildPipGrid(int count) {
    if (count == 0) return const SizedBox.shrink();
    return Text(
      '$count',
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w900,
        fontSize: 16,
      ),
    );
  }
}

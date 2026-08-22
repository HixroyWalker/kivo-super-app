import 'package:flutter/material.dart';
import '../../../core/theme/dark_theme.dart';
import 'checkers_game_screen.dart';
import 'dominoes_game_screen.dart';
import 'ludo_game_screen.dart';
import 'snakes_and_ladders_game_screen.dart';

class GamesHubScreen extends StatelessWidget {
  const GamesHubScreen({super.key});

  void _showCheckersModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KivoDarkTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.sports_esports, color: KivoDarkTheme.primaryEmerald, size: 24),
            SizedBox(width: 10),
            Text('Jamaican Checkers 🇯🇲', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose your game mode:', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0x2600E676),
                child: Icon(Icons.smart_toy, color: KivoDarkTheme.primaryEmerald),
              ),
              title: const Text('Play vs Kivo AI Bot', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Single player practice with intelligent moves', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: KivoDarkTheme.primaryEmerald),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckersGameScreen(gameMode: 'vs_ai')),
                );
              },
            ),
            const Divider(color: KivoDarkTheme.surfaceBorder),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0x2600E5FF),
                child: Icon(Icons.people, color: KivoDarkTheme.accentCyan),
              ),
              title: const Text('Pass & Play (2-Player)', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Play side-by-side with a friend on 1 phone', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: KivoDarkTheme.accentCyan),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckersGameScreen(gameMode: 'pass_and_play')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDominoesModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KivoDarkTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.casino, color: Color(0xFFFFD700), size: 24),
            SizedBox(width: 10),
            Text('Jamaican Dominoes 🁓 🇯🇲', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Double-Six Cut Throat & Six-Love Rules:', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0x26FFD700),
                child: Icon(Icons.smart_toy, color: Color(0xFFFFD700)),
              ),
              title: const Text('Play vs Buju (Jamaican AI)', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Authentic 28-bone cut throat game with boneyard', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFFFD700)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DominoesGameScreen(gameMode: 'vs_ai')),
                );
              },
            ),
            const Divider(color: KivoDarkTheme.surfaceBorder),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0x2600E676),
                child: Icon(Icons.people, color: KivoDarkTheme.primaryEmerald),
              ),
              title: const Text('Pass & Play (2-Player)', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Play heads-up against a friend on 1 device', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: KivoDarkTheme.primaryEmerald),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DominoesGameScreen(gameMode: 'pass_and_play')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLudoModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KivoDarkTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.grid_view_rounded, color: KivoDarkTheme.accentCyan, size: 24),
            SizedBox(width: 10),
            Text('Jamaican Ludo 🎲 🇯🇲', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Classic 4-Player Caribbean Board Game:', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0x2600E5FF),
                child: Icon(Icons.smart_toy, color: KivoDarkTheme.accentCyan),
              ),
              title: const Text('Play vs 3 Kivo AI Bots', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Red (You) vs Blue, Green & Yellow AI players', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: KivoDarkTheme.accentCyan),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LudoGameScreen(gameMode: 'vs_ai')),
                );
              },
            ),
            const Divider(color: KivoDarkTheme.surfaceBorder),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0x2600E676),
                child: Icon(Icons.people, color: KivoDarkTheme.primaryEmerald),
              ),
              title: const Text('4-Player Pass & Play', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Play with up to 4 friends on 1 phone', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: KivoDarkTheme.primaryEmerald),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LudoGameScreen(gameMode: 'pass_and_play')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSnakesModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KivoDarkTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.directions_run, color: Color(0xFFE53935), size: 24),
            SizedBox(width: 10),
            Text('Snakes & Ladders 🐍 🇯🇲', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Race to 100 on the jungle board:', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0x26E53935),
                child: Icon(Icons.smart_toy, color: Color(0xFFE53935)),
              ),
              title: const Text('Play vs Buju AI', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Single player practice with intelligent moves', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFE53935)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SnakeAndLaddersGameScreen(gameMode: 'vs_ai')),
                );
              },
            ),
            const Divider(color: KivoDarkTheme.surfaceBorder),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0x261E88E5),
                child: Icon(Icons.people, color: Color(0xFF1E88E5)),
              ),
              title: const Text('Pass & Play (2-Player)', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Play side-by-side with a friend on 1 phone', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF1E88E5)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SnakeAndLaddersGameScreen(gameMode: 'pass_and_play')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KivoDarkTheme.background,
      appBar: AppBar(
        title: const Text('Kivo Games & Arcade 🎲'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Playable Game 1: Jamaican Checkers
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B3A2B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KivoDarkTheme.primaryEmerald),
                boxShadow: [
                  BoxShadow(color: KivoDarkTheme.primaryEmerald.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: KivoDarkTheme.primaryEmerald,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('READY TO PLAY', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      const Text('🇯🇲 Classic Island Board Game', style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Jamaican Checkers (Draughts)',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Play 8x8 classic Jamaican draughts with flying king promotions and multi-jump captures. Challenge Kivo AI or play with friends!',
                    style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCheckersModeDialog(context),
                      icon: const Icon(Icons.play_arrow, color: Colors.black, size: 22),
                      label: const Text('PLAY CHECKERS NOW', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KivoDarkTheme.primaryEmerald,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Playable Game 2: Jamaican Dominoes
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3E2723), Color(0xFF1B1B1B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.6)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('READY TO PLAY', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      const Text('🁓 Double-Six Cut Throat', style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Jamaican Dominoes (Six Love 🇯🇲)',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Authentic Caribbean domino table with 28 bones, chain matching, boneyard drawing, hard knocks, and Six-Love tournament scoring!',
                    style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _showDominoesModeDialog(context),
                      icon: const Icon(Icons.casino, color: Colors.black, size: 22),
                      label: const Text('PLAY DOMINOES NOW', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Playable Game 3: Jamaican Ludo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D253F), Color(0xFF1E1B4B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KivoDarkTheme.accentCyan.withOpacity(0.6)),
                boxShadow: [
                  BoxShadow(color: KivoDarkTheme.accentCyan.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: KivoDarkTheme.accentCyan,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('READY TO PLAY', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      const Text('🎲 4-Player Caribbean Classic', style: TextStyle(color: KivoDarkTheme.accentCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Jamaican Ludo & Crown 🎲',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Classic 4-color Caribbean Ludo board with 3D dice rolls, home base deployment, opponent token captures, and victory podium!',
                    style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _showLudoModeDialog(context),
                      icon: const Icon(Icons.grid_view_rounded, color: Colors.black, size: 22),
                      label: const Text('PLAY LUDO NOW', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KivoDarkTheme.accentCyan,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Playable Game 4: Snakes & Ladders
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B4332), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.6)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('NEW GAME', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      const Text('🐍 Jungle Run', style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Snakes & Ladders 🐍',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Race to 100 on the treacherous jungle board! Climb the ladders and avoid sliding down the snakes.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _showSnakesModeDialog(context),
                      icon: const Icon(Icons.directions_run, color: Colors.black, size: 22),
                      label: const Text('PLAY SNAKES NOW', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Leaderboard & Stats
            const Text('Arcade Leaderboard & Stats', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KivoDarkTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KivoDarkTheme.surfaceBorder),
              ),
              child: Column(
                children: [
                  _buildLeaderboardRow(1, 'Marcus Bailey', '142 Wins', '2,450 ELO', const Color(0xFFFFD700)),
                  const Divider(color: KivoDarkTheme.surfaceBorder),
                  _buildLeaderboardRow(2, 'Damian Clarke', '98 Wins', '2,180 ELO', const Color(0xFFE0E0E0)),
                  const Divider(color: KivoDarkTheme.surfaceBorder),
                  _buildLeaderboardRow(3, 'Hixroy Walker (You)', '64 Wins', '1,950 ELO', const Color(0xFFCD7F32)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardRow(int rank, String name, String wins, String rating, Color medalColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: medalColor.withOpacity(0.2),
            child: Text('$rank', style: TextStyle(color: medalColor, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Text(wins, style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
          const SizedBox(width: 12),
          Text(rating, style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

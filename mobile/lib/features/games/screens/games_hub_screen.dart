import 'package:flutter/material.dart';
import '../../../core/theme/dark_theme.dart';
import 'checkers_game_screen.dart';

class GamesHubScreen extends StatelessWidget {
  const GamesHubScreen({super.key});

  void _showGameModeDialog(BuildContext context) {
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
            // 1. Featured Playable Game Hero: Jamaican Checkers
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
                      onPressed: () => _showGameModeDialog(context),
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
            const SizedBox(height: 28),

            // 2. Upcoming Games Grid
            const Text('Island Games Arcade', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KivoDarkTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: KivoDarkTheme.surfaceBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0x26FFD700),
                          radius: 20,
                          child: Icon(Icons.casino, color: Color(0xFFFFD700), size: 22),
                        ),
                        const SizedBox(height: 12),
                        const Text('Jamaican Dominoes', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text('Cut Throat & Six Love rules coming soon', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                          child: const Text('COMING SOON', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KivoDarkTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: KivoDarkTheme.surfaceBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0x2600E5FF),
                          radius: 20,
                          child: Icon(Icons.grid_view_rounded, color: KivoDarkTheme.accentCyan, size: 22),
                        ),
                        const SizedBox(height: 12),
                        const Text('Ludo & Crown', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text('Traditional 4-player multiplayer arcade', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                          child: const Text('COMING SOON', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // 3. Leaderboard & Stats
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

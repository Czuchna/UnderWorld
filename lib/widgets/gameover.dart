import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:underworld_game/game.dart';
import 'package:underworld_game/router.dart';

class GameOverOverlay extends StatelessWidget {
  final MyGame gameRef;

  const GameOverOverlay({super.key, required this.gameRef});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Game Over',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Przejście do głównego menu
              context.router.replace(const MainMenuRoute());
              gameRef.reset(); // Reset gry
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              'Back to Main Menu',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

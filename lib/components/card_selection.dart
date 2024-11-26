import 'package:flutter/material.dart';
import 'package:underworld_game/game.dart';

class CardSelectionWidget extends StatelessWidget {
  final MyGame game;

  const CardSelectionWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final List<String> cards = [
      "Ballista Tower",
      "Increase Damage +10",
      "Increase Player Speed",
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Choose Your Upgrade",
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: cards.map((card) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0), // Dodanie odstępu między kartami
                  child: GestureDetector(
                    onTap: () {
                      game.handleCardSelection(card); // Wywołanie metody w grze
                      Navigator.pop(context);
                    },
                    child: Card(
                      color: Colors.blue,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          card,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
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
}

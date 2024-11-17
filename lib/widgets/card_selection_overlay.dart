import 'package:flutter/material.dart';
import 'package:underworld_game/game.dart';

class CardSelectionOverlay extends StatelessWidget {
  final MyGame game;

  const CardSelectionOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final cards = game.availableCards;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black.withOpacity(0.8), // Tło półprzezroczyste
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Choose Your Upgrade",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20, // Odległość między kartami
              runSpacing: 10, // Odległość między rzędami kart
              children: cards.map((card) {
                return GestureDetector(
                  onTap: () {
                    _onCardSelected(context, card);
                  },
                  child: Container(
                    width: 120, // Szerokość pojedynczej karty
                    height: 150, // Wysokość pojedynczej karty
                    margin: const EdgeInsets.all(5),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        card,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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

  void _onCardSelected(BuildContext context, String card) {
    if (card == "Increase Player Damage") {
      game.player.damage += 10; // Zwiększenie obrażeń gracza
    } else if (card == "Increase Player Speed") {
      game.player.speed += 50; // Zwiększenie prędkości gracza
    } else if (card == "Add Ballista Tower") {
      game.selectedCards.add("Ballista Tower"); // Dodanie wieży do dostępnych
    }

    game.resumeGame(); // Wznów grę po wyborze karty
    game.overlays.remove('CardSelection'); // Usuń nakładkę
  }
}

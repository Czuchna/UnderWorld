import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:underworld_game/game.dart';
import 'package:underworld_game/widgets/gameover.dart';
import 'package:underworld_game/widgets/winoverlay.dart';

@RoutePage()
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MyGame game = MyGame();

    return Scaffold(
      body: Stack(
        children: [
          GameWidget(
            game: game,
            overlayBuilderMap: {
              // Dodajemy nakładki dla slotów
              for (final slot in game.towerSlots)
                'TowerSlot-${slot.row}-${slot.col}': (context, MyGame gameRef) {
                  return Positioned(
                    left: slot.position.x,
                    top: slot.position.y,
                    child: slot.buildSlotWidget(),
                  );
                },
              // Nakładka ekranu przegranej
              'GameOverOverlay': (context, MyGame gameRef) =>
                  GameOverOverlay(gameRef: gameRef),
              // Nakładka ekranu wygranej
              'WinOverlay': (context, MyGame gameRef) =>
                  WinOverlay(gameRef: gameRef),
            },
          ),
        ],
      ),
    );
  }
}

import 'dart:developer';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:underworld_game/models/tower.dart';
import 'package:underworld_game/game.dart';

class TowerSlot extends PositionComponent
    with HasGameRef<MyGame>, TapCallbacks, CollisionCallbacks {
  final int row; // Rząd w siatce
  final int col; // Kolumna w siatce

  TowerSlot({required this.row, required this.col, required Vector2 position})
      : super(
          position: position,
          size: Vector2(80, 80), // Rozmiar slotu
        );

  bool isOccupied = false; // Czy slot jest zajęty
  late Paint _slotPaint;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    log("TowerSlot loaded at position: $position (row: $row, col: $col)");

    // Ustawienie koloru dla slotu
    _slotPaint = Paint()..color = Colors.green.withOpacity(0.1);

    add(RectangleHitbox()
      ..collisionType = CollisionType.passive); // Dodanie kolizji
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Kolor slotu w zależności od stanu
    _slotPaint.color = isOccupied
        ? Colors.red.withOpacity(0.5)
        : Colors.green.withOpacity(0.12);

    // Rysowanie prostokąta slotu
    canvas.drawRect(size.toRect(), _slotPaint);

    // Dodanie ramki debugującej
    final borderPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(size.toRect(), borderPaint);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!isOccupied) {
      final availableCards =
          gameRef.selectedCards; // Uzyskanie dostępnych kart z MyGame

      if (availableCards.isEmpty) {
        log("No available cards to place.");
        return;
      }

      // Wyświetlenie dialogu wyboru wieży
      showDialog(
        context: gameRef.buildContext!, // Użycie buildContext z gameRef
        builder: (context) {
          return AlertDialog(
            title: const Text("Choose a Tower"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: availableCards.map((tower) {
                return ListTile(
                  title: Text(tower),
                  onTap: () {
                    // Dodanie wybranej wieży
                    final newTower = Tower(
                      position: position,
                      attackRange: 200,
                      attackDamage: 20,
                      attackInterval: 1.0,
                    );
                    gameRef.add(newTower); // Dodanie wieży do gry
                    isOccupied = true;

                    // Aktualizacja siatki w MyGame
                    gameRef.updateGrid(row, col, true);

                    // Usunięcie wybranej karty z dostępnych kart
                    gameRef.selectedCards.remove(tower);

                    // Ustawienie slotu jako przeszkody
                    add(RectangleHitbox()
                      ..collisionType = CollisionType.active);

                    Navigator.pop(context); // Zamknięcie dialogu
                  },
                );
              }).toList(),
            ),
          );
        },
      );
    } else {
      log("Slot already occupied.");
    }
  }

  void buildTower() {
    if (!isOccupied) {
      isOccupied = true;

      gameRef.updateGrid(row, col, true);

      gameRef.updateEnemyPaths();
    }
  }
}

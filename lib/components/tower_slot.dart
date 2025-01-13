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
  bool isOccupied; // Czy slot jest zajęty
  late Paint _slotPaint;

  TowerSlot({
    required this.isOccupied,
    required this.row,
    required this.col,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(80, 80), // Rozmiar slotu
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    log("TowerSlot loaded at position: $position (row: $row, col: $col)");

    // Ustawienie koloru dla slotu
    _slotPaint = Paint()..color = Colors.green.withOpacity(0.1);

    // Dodanie hitboxa dla kolizji
    add(RectangleHitbox()..collisionType = CollisionType.passive);
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

    // Ramka debugująca
    final borderPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(size.toRect(), borderPaint);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!isOccupied) {
      _showTowerSelectionDialog();
    } else {
      log("Slot already occupied.");
    }
  }

  void _showTowerSelectionDialog() {
    final availableCards = gameRef.selectedCards;

    if (availableCards.isEmpty) {
      log("No available cards to place.");
      return;
    }

    // Wyświetlenie dialogu wyboru wieży
    showDialog(
      context: gameRef.buildContext!,
      builder: (context) {
        return AlertDialog(
          title: const Text("Choose a Tower"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableCards.map((tower) {
              return ListTile(
                title: Text(tower),
                onTap: () {
                  _placeTower(tower);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _placeTower(String tower) {
    // Tworzenie nowej wieży
    final newTower = Tower(
      position: position,
      attackRange: 200,
      attackDamage: 20,
      attackInterval: 1.0,
    );

    // Dodanie wieży do gry
    gameRef.add(newTower);

    // Oznaczenie slotu jako zajętego
    isOccupied = true;

    // Aktualizacja siatki przeszkód
    gameRef.grid.setOccupied(row, col, true);

    log("Tower placed at position: $position. Slot marked as occupied.");

    // Zaktualizowanie ścieżek przeciwników
    gameRef.updateEnemyPaths();
  }
}

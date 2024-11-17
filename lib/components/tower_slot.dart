import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:underworld_game/components/tower.dart';
import 'package:underworld_game/game.dart';

class TowerSlot extends PositionComponent
    with HasGameRef<MyGame>, DragCallbacks {
  TowerSlot({required Vector2 position})
      : super(
          position: position,
          size: Vector2(80, 80), // Size of the slot
        );

  bool isOccupied = false; // Whether the slot is already occupied
  late Paint _slotPaint;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    print("TowerSlot loaded at position: $position");

    // Set color for the slot
    _slotPaint = Paint()..color = Colors.green.withOpacity(0.5);

    add(RectangleHitbox()); // Add collision
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Draw the slot
    canvas.drawRect(size.toRect(), _slotPaint);
  }

  @override
  bool onTapDown(TapDownInfo info) {
    if (!isOccupied) {
      final availableCards =
          gameRef.selectedCards; // Access the selected cards from MyGame

      if (availableCards.isEmpty) {
        print("No available cards to place.");
        return false;
      }

      showDialog(
        context: gameRef.buildContext!, // Use gameRef's buildContext
        builder: (context) {
          return AlertDialog(
            title: const Text("Choose a Tower"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: availableCards.map((tower) {
                return ListTile(
                  title: Text(tower),
                  onTap: () {
                    // Add the selected tower
                    final newTower = Tower(
                      position: position,
                      attackRange: 150,
                      attackDamage: 20,
                      attackInterval: 1.0,
                    );
                    gameRef.add(newTower);
                    isOccupied = true;
                    Navigator.pop(context); // Close the dialog
                  },
                );
              }).toList(),
            ),
          );
        },
      );
    } else {
      print("Slot already occupied.");
    }
    return true;
  }
}

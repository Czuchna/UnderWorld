import 'dart:developer';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:underworld_game/game.dart';

class TowerSlot extends PositionComponent
    with HasGameRef<MyGame>, TapCallbacks, CollisionCallbacks {
  final int row;
  final int col;
  bool isOccupied;

  TowerSlot({
    required this.isOccupied,
    required this.row,
    required this.col,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(80, 80),
        );
  @override
  int get priority => 50;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    log("TowerSlot loaded at position: $position (row: $row, col: $col)");
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  Widget buildSlotWidget() {
    return DragTarget<String>(
      onWillAcceptWithDetails: (DragTargetDetails<String> details) {
        final canAccept = !isOccupied && details.data == "Add Ballista Tower";
        debugPrint(
            'onWillAcceptWithDetails: Slot=($row, $col), CanAccept=$canAccept, Data=${details.data}');
        return canAccept;
      },
      onAcceptWithDetails: (DragTargetDetails<String> details) {
        debugPrint('onAcceptWithDetails: Accepted=${details.data}');
        isOccupied = true; // Oznacz slot jako zajęty
        gameRef.selectedCards.remove(details.data); // Usuń kartę z dostępnych
        gameRef.addTowerAtSlot(row, col, details.data); // Dodaj wieżę do gry
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            border: Border.all(
              color: Colors.green,
              width: 1,
            ),
          ),
          width: 80,
          height: 80,
        );
      },
    );
  }
}

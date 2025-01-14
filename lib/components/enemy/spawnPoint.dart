import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SpawnPoint extends PositionComponent {
  SpawnPoint(Vector2 position)
      : super(
          position: position,
          size: Vector2(20, 20), // Wizualny rozmiar punktu spawnu
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFF00FF00).withOpacity(0.5),
    ));
  }
}

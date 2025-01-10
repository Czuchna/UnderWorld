import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GameBounds extends RectangleComponent {
  GameBounds(Vector2 position, Vector2 size)
      : super(
          position: position,
          size: size,
          paint: Paint()
            ..color =
                const Color(0xFF00FF00).withOpacity(0.5), // Zielone krawędzie
        );
}

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class StartButton extends PositionComponent {
  final String text;
  final VoidCallback onPressed;

  StartButton({
    required this.text,
    required Vector2 position,
    required this.onPressed,
  }) {
    this.position = position;
    size = Vector2(100, 40); // Rozmiar przycisku
  }

  @override
  void render(Canvas canvas) {
    // Rysowanie prostokątnego przycisku
    final paint = Paint()..color = Colors.blue;
    canvas.drawRect(size.toRect(), paint);

    // Rysowanie tekstu na przycisku
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = Offset(
      size.x / 2 - textPainter.width / 2,
      size.y / 2 - textPainter.height / 2,
    );
    textPainter.paint(canvas, position.toOffset() + offset);
  }

  bool onTapDown(TapDownInfo info) {
    onPressed();
    return true;
  }
}

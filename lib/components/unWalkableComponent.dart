import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

class UnwalkableComponent extends RectangleComponent with CollisionCallbacks {
  UnwalkableComponent({
    required Vector2 position,
    required Vector2 size,
    Paint? paint,
  }) : super(
          position: position,
          size: size,
          paint: paint ??
              (Paint()..color = const Color(0xFF000000).withOpacity(0.5)),
        );

  @override
  @override
  Future<void> onLoad() async {
    super.onLoad();
  }

  Vector2 globalPosition() {
    return absolutePosition;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Opcjonalnie: Rysowanie debugowej ramki
    final borderPaint = Paint()
      ..color =
          const Color(0xFFFF0000).withOpacity(0.8) // Czerwony kolor debugowy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(size.toRect(), borderPaint);
  }
}

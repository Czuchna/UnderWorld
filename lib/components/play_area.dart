import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game.dart'; // Import twojej głównej klasy gry

class PlayArea extends RectangleComponent with HasGameRef<MyGame> {
  PlayArea()
      : super(
          paint: Paint()..color = Colors.transparent,
          children: [RectangleHitbox()],
        );

  @override
  FutureOr<void> onLoad() async {
    super.onLoad();
    size = gameRef.size;
    position = Vector2.zero();
  }
}

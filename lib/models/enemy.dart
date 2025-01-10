import 'dart:developer';

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:underworld_game/game.dart';
import 'package:underworld_game/utils/algorithm.dart';

class Enemy extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  double healthPoints;
  final double maxHealthPoints;
  final double speed = 50;
  Function()? onReachBottom;
  VoidCallback? onDefeated;
  List<Vector2> path = [];
  bool recalculatingPath = false;

  late RectangleComponent healthBar;
  late RectangleComponent healthBarBackground;

  Enemy({
    required Vector2 position,
    required this.healthPoints,
  })  : maxHealthPoints = healthPoints,
        super(
          position: position,
          size: Vector2(70, 70),
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    sprite = await gameRef.loadSprite('enemy.png');
    add(RectangleHitbox()..collisionType = CollisionType.active);

    healthBarBackground = RectangleComponent(
      position: Vector2(0, -10),
      size: Vector2(size.x, 5),
      paint: Paint()..color = Colors.grey,
    );
    add(healthBarBackground);

    healthBar = RectangleComponent(
      position: Vector2(0, -10),
      size: Vector2(size.x, 5),
      paint: Paint()..color = Colors.red,
    );
    add(healthBar);

    calculatePath();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (path.isEmpty) {
      calculatePath(); // Przelicz ścieżkę, jeśli pusta
      return;
    }

    final target = path.first;

    // Kierunek ruchu przeciwnika
    final moveDirection = (target - position).normalized();
    Vector2 nextPosition = position + moveDirection * speed * dt;

    // Ograniczenie ruchu w granicach gry
    nextPosition.x = nextPosition.x.clamp(
      gameRef.gameBounds.left + size.x / 2,
      gameRef.gameBounds.right - size.x / 2,
    );
    nextPosition.y = nextPosition.y.clamp(
      gameRef.gameBounds.top + size.y / 2,
      gameRef.gameBounds.bottom - size.y / 2,
    );

    position = nextPosition;

    // Jeśli osiągnie cel w ścieżce, usuń ten cel z listy
    if ((target - position).length < 10) {
      path.removeAt(0);
    }

    // Sprawdzenie, czy przeciwnik dotarł na dół planszy
    if (position.y + size.y >= gameRef.gameBounds.bottom) {
      log('Enemy reached the bottom at $position');
      onReachBottom?.call(); // Odejmij życie gracza
      removeFromParent();
    }
  }

  void takeDamage(double damage) {
    healthPoints -= damage;
    healthBar.size.x = (healthPoints / maxHealthPoints) * size.x;

    if (healthPoints <= 0) {
      onDefeated?.call();
      removeFromParent();
    }
  }

  void calculatePath() {
    // Indeksy siatki dla pozycji startowej przeciwnika
    Vector2 gridIndices = gameRef.positionToGridIndices(position);
    int startRow = gridIndices.x.toInt();
    int startCol = gridIndices.y.toInt();

    // Cel: dolny rząd, środkowa kolumna
    int endRow = MyGame.gridSize - 1;
    int endCol = (MyGame.gridSize / 2).floor();

    log('Calculating path from ($startRow, $startCol) to ($endRow, $endCol)');

    List<Node> nodePath = gameRef.findPath(startRow, startCol, endRow, endCol);

    if (nodePath.isNotEmpty) {
      final double pathHeight = gameRef.size.y * 0.25;

      // Tworzenie ścieżki opartej na węzłach
      path = nodePath.map((node) {
        return Vector2(
          node.col * MyGame.slotSize + MyGame.slotSize / 2,
          node.row * MyGame.slotSize + MyGame.slotSize / 2 + pathHeight,
        );
      }).toList();
    } else {
      log('No valid path found. Moving straight down.');

      // Jeżeli nie ma ścieżki, poruszaj się w dół, unikając granic
      double fallbackX = position.x.clamp(
        MyGame.slotSize / 2, // Lewa granica
        gameRef.size.x - MyGame.slotSize / 2, // Prawa granica
      );
      path = [Vector2(fallbackX, gameRef.size.y)];
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Jeśli przeciwnik zderzy się z granicą lub przeszkodą
    if (other is RectangleHitbox) {
      log('Enemy collided with boundary at $position, recalculating path.');
      calculatePath(); // Przelicz nową ścieżkę
    }
  }

  @override
  void onRemove() {
    super.onRemove();
    log("Enemy removed: Health was $healthPoints");
  }
}

import 'dart:developer';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:underworld_game/components/aStarPathfinder.dart';
import 'package:underworld_game/components/gameBoundries.dart';
import 'package:underworld_game/components/tower_slot.dart';
import 'package:underworld_game/game.dart';

class Enemy extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  double healthPoints;
  final double maxHealthPoints;
  final double speed = 50;
  Function()? onReachBottom;
  VoidCallback? onDefeated;
  List<Vector2> path = [];
  late GameBounds gameBounds;

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
  void onMount() {
    super.onMount();
    gameBounds =
        gameRef.children.firstWhere((c) => c is GameBounds) as GameBounds;

    calculatePath();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    sprite = await gameRef.loadSprite('enemy.png');
    add(RectangleHitbox()..collisionType = CollisionType.active);

    // Pasek zdrowia
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
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Podążanie za ścieżką
    if (path.isNotEmpty) {
      final target = path.first;
      final moveDirection = (target - position).normalized();
      position += moveDirection * speed * dt;

      if ((target - position).length < 10) {
        path.removeAt(0);
      }
    }

    // Ograniczenie do granic gry
    position.x = position.x.clamp(
      gameBounds.position.x,
      gameBounds.position.x + gameBounds.size.x - size.x,
    );
    position.y = position.y.clamp(
      gameBounds.position.y,
      gameBounds.position.y + gameBounds.size.y - size.y,
    );

    // Jeśli dotarł do dolnej krawędzi
    if (position.y >= gameBounds.size.y) {
      onReachBottom?.call();
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
    final obstacles = gameRef.children
        .whereType<TowerSlot>()
        .where((slot) => slot.isOccupied)
        .map((slot) => RectangleComponent(
              position: slot.position.clone(),
              size: slot.size.clone(),
              paint: Paint()..color = Colors.transparent,
            ))
        .toList();

    log('Obstacles in path calculation: ${obstacles.map((o) => o.position).join(", ")}');

    final start = position.clone();
    final target = Vector2(gameBounds.size.x / 2, gameBounds.size.y);

    final pathfinder = AStarPathfinder(
      obstacles: obstacles,
      gridSize: gameBounds.size,
    );
    path = pathfinder.findPath(start, target);

    if (path.isEmpty) {
      path = [Vector2(position.x, gameBounds.size.y)];
    }
  }
}

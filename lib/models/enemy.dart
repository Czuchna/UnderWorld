// Aktualizacja pliku enemy.dart

import 'dart:developer';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:underworld_game/components/aStarPathFinder_dart';
import 'package:underworld_game/components/tower_slot.dart';
import 'package:underworld_game/components/unWalkableComponent.dart';
import 'package:underworld_game/game.dart';

class Enemy extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  double healthPoints;
  final double maxHealthPoints;
  final double speed = 50;
  Function()? onReachBottom;
  VoidCallback? onDefeated;
  List<Vector2> path = [];

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
    log("Enemy added to game tree at position: $position");

    // Oblicz ścieżkę dopiero po dodaniu przeciwnika do gry
    calculatePath();
  }

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
  }

  int recalculationAttempts = 0; // Dodaj zmienną do śledzenia liczby prób

  @override
  void update(double dt) {
    super.update(dt);

    // Jeśli ścieżka istnieje, podążaj za nią
    if (path.isNotEmpty) {
      final target = path.first;
      final moveDirection = (target - position).normalized();

      position += moveDirection * speed * dt;

      // Jeśli osiągną punkt, przechodzą do następnego w ścieżce
      if ((target - position).length < 10) {
        log("Enemy reached waypoint $target");
        path.removeAt(0);
      }
    }

    // Sprawdź, czy aktualna pozycja jest w przeszkodzie
    final obstacles =
        gameRef.children.whereType<UnwalkableComponent>().toList();
    for (final obstacle in obstacles) {
      final rect = obstacle.toRect();
      if (rect.contains(Offset(position.x, position.y))) {
        log("Enemy at $position is inside obstacle at ${obstacle.position}. Recalculating path...");
        calculatePath();
        break;
      }
    }

    // Ograniczenie ruchu do obszaru gry
    position.x = position.x.clamp(0, gameRef.size.x - size.x);
    position.y = position.y.clamp(0, gameRef.size.y - size.y);

    // Jeśli potwór dotarł do końca ekranu
    if (position.y >= gameRef.size.y) {
      log("Enemy reached the bottom!");
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
    // Pobieramy wszystkie zajęte sloty jako przeszkody
    final obstacles = gameRef.children
        .whereType<TowerSlot>()
        .where((slot) => slot.isOccupied)
        .map((slot) => RectangleComponent(
              position: slot.position.clone(),
              size: slot.size,
              paint: Paint()..color = Colors.transparent,
            ))
        .toList();

    log("Obstacles count: ${obstacles.length}");

    // Punkt startowy (pozycja potwora) i docelowy (środek dolnej krawędzi ekranu)
    final start = position.clone();
    final target = Vector2(gameRef.size.x / 2, gameRef.size.y);

    // Wywołujemy algorytm A* z listą przeszkód
    final pathfinder =
        AStarPathfinder(obstacles: obstacles, gridSize: gameRef.size);
    path = pathfinder.findPath(start, target);

    log("Calculated path: ${path.map((p) => '[${p.x}, ${p.y}]').join(' -> ')}");

    if (path.isEmpty) {
      log("No valid path found. Falling back to straight line.");
      path = [Vector2(start.x, target.y)];
    }
  }
}

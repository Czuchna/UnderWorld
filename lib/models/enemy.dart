import 'dart:developer';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:underworld_game/components/aStarPathfinder.dart';
import 'package:underworld_game/game.dart';

class Enemy extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  double healthPoints;
  final double maxHealthPoints;
  final double speed;
  Function()? onReachBottom;
  VoidCallback? onDefeated;
  List<Vector2> path = [];

  late RectangleComponent healthBar;
  late RectangleComponent healthBarBackground;

  Enemy({
    required Vector2 position,
    required this.healthPoints,
    this.speed = 50,
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

    // Pasek zdrowia
    _initializeHealthBar();
  }

  void _initializeHealthBar() {
    // Tło paska zdrowia
    healthBarBackground = RectangleComponent(
      position: Vector2(0, -10),
      size: Vector2(size.x, 5),
      paint: Paint()..color = Colors.grey,
    );
    add(healthBarBackground);

    // Pasek zdrowia
    healthBar = RectangleComponent(
      position: Vector2(0, -10),
      size: Vector2(size.x, 5),
      paint: Paint()..color = Colors.red,
    );
    add(healthBar);
  }

  @override
  void onMount() {
    super.onMount();
    calculatePath();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _followPath(dt);

    // Sprawdzenie, czy dotarł do dolnej krawędzi
    // Sprawdzenie, czy potwór dotarł do ostatniego rzędu siatki
    if (position.y + size.y >= gameRef.size.y) {
      print('dotarl');
      onReachBottom?.call();
      removeFromParent();
    }
  }

  void _followPath(double dt) {
    if (path.isNotEmpty) {
      final target = path.first;

      // Sprawdź, czy następny punkt na ścieżce jest przeszkodą
      final col = (target.x / 80).floor();
      final row = (target.y / 80).floor();
      if (gameRef.grid.isOccupied(row, col)) {
        log('Target $target is occupied. Recalculating path.');
        calculatePath();
        return;
      }

      final moveDirection = (target - position).normalized();
      position += moveDirection * speed * dt;

      if ((target - position).length < 5) {
        path.removeAt(0);
      }
    }
  }

  void takeDamage(double damage) {
    healthPoints -= damage;
    healthBar.size.x = (healthPoints / maxHealthPoints) * size.x;

    if (healthPoints <= 0) {
      _onDeath();
    }
  }

  void _onDeath() {
    onDefeated?.call();
    removeFromParent();
  }

  void calculatePath() {
    log('Calculating path for enemy at position: $position');

    // Wyrównanie pozycji startowej i celu do siatki
    Vector2 start = _alignToGrid(position);
    Vector2 target = Vector2(position.x, gameRef.size.y - size.y + 80);

    // Pobranie mapy przeszkód z gridu
    final obstacleMap = gameRef.grid.toObstacleMap();

    final pathfinder = AStarPathfinder(
      grid: gameRef.grid,
      obstacleMap: obstacleMap,
    );

    // Znalezienie ścieżki
    path = pathfinder.findPath(start, target);

    if (path.isEmpty) {
      log('No valid path found. Moving directly downwards.');
      path = [Vector2(position.x, gameRef.size.y)];
    } else {
      log('Path found: $path');
    }
  }

  /// Wyrównanie punktu do siatki
  Vector2 _alignToGrid(Vector2 point) {
    final alignedX = (point.x / 80).floor() * 80.0;
    final alignedY = (point.y / 80).floor() * 80.0;
    return Vector2(alignedX, alignedY);
  }
}

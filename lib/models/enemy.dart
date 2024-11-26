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
  void render(Canvas canvas) {
    super.render(canvas);

    // Rysowanie ścieżki
    if (path.length > 1) {
      Paint paint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 2;
      for (int i = 0; i < path.length - 1; i++) {
        canvas.drawLine(path[i].toOffset(), path[i + 1].toOffset(), paint);
      }
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    sprite = await gameRef.loadSprite('enemy.png');
    add(RectangleHitbox()..collisionType = CollisionType.active);

    // Dodanie obrysu dla widoczności
    add(RectangleComponent(
      position: Vector2(0, 0),
      size: size,
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.green,
    ));

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

    if (path.isEmpty && !recalculatingPath) {
      recalculatingPath = true;
      calculatePath();
      recalculatingPath = false;
      return;
    }

    if (path.isNotEmpty) {
      final target = path.first;

      // Kierunek ruchu przeciwnika
      final moveDirection = (target - position).normalized();
      position += moveDirection * speed * dt;

      // Jeśli przeciwnik osiągnie cel w ścieżce, usuń ten cel z listy
      if ((target - position).length < 10) {
        path.removeAt(0);
      }
    }

    // Sprawdzenie, czy przeciwnik dotarł do ostatniej kratki (dolnej krawędzi planszy)
    final bottomThreshold =
        (MyGame.gridSize - 1) * MyGame.slotSize + MyGame.slotSize / 2;
    if (position.y >= bottomThreshold) {
      if (onReachBottom != null) {
        onReachBottom!(); // Wywołanie zdarzenia
      }
      removeFromParent(); // Usunięcie przeciwnika
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
    Vector2 gridIndices = gameRef.positionToGridIndices(position);
    int startRow = gridIndices.x.toInt();
    int startCol = gridIndices.y.toInt();

    // Cel: dolna środkowa kolumna siatki
    int endRow = MyGame.gridSize - 1;
    int endCol = (MyGame.gridSize / 2).floor();

    print('Calculating path from ($startRow, $startCol) to ($endRow, $endCol)');

    List<Node> nodePath = gameRef.findPath(startRow, startCol, endRow, endCol);

    if (nodePath.isNotEmpty) {
      // Pobierz pathHeight z MyGame
      final double pathHeight = gameRef.size.y * 0.25;

      path = nodePath.map((node) {
        return Vector2(
          node.col * MyGame.slotSize + MyGame.slotSize / 2,
          node.row * MyGame.slotSize +
              MyGame.slotSize / 2 +
              pathHeight, // Dodaj pathHeight
        );
      }).toList();
      print('Path calculated: $path');
    } else {
      // Jeśli nie ma ścieżki, przeciwnik idzie prosto w dół
      path = [
        Vector2(position.x, MyGame.gridSize * MyGame.slotSize.toDouble())
      ];
      print('No path found, moving straight down.');
    }
  }

  @override
  void onRemove() {
    super.onRemove();
    print("Enemy removed: Health was $healthPoints");
  }
}

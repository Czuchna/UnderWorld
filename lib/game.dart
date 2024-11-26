import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:underworld_game/models/enemy.dart';
import 'package:underworld_game/models/player.dart';
import 'package:underworld_game/components/joystick.dart';
import 'package:underworld_game/components/tower_slot.dart';
import 'package:underworld_game/utils/algorithm.dart';
import 'package:underworld_game/widgets/card_selection_overlay.dart';
import 'package:underworld_game/widgets/gameover.dart';
import 'package:underworld_game/widgets/winoverlay.dart';
import 'package:underworld_game/components/hud.dart';

class MyGame extends FlameGame with HasCollisionDetection, DragCallbacks {
  late Player player;
  late HudComponent hudComponent;
  late Rect spawnAreaRect;
  final List<String> selectedCards = [];
  int currentWave = 1;
  final int totalWaves = 10;
  final int baseEnemiesPerWave = 5;
  int remainingEnemies = 0;
  int lives = 3;
  int playerLevel = 1;
  int currentExp = 0;
  int nextLevelExp = 10;
  bool isPaused = false;

  static const int gridSize = 10; // Rozmiar siatki (10x10)
  static const double slotSize = 80.0; // Rozmiar jednego slotu
  final List<List<bool>> grid = List.generate(
    gridSize,
    (_) => List.generate(
        gridSize, (_) => false), // Wszystkie pola początkowo wolne
  );

  void updateGrid(int row, int col, bool isOccupied) {
    grid[row][col] = isOccupied;
  }

  bool isOccupied(int row, int col) {
    return grid[row][col];
  }

  final List<String> availableCards = [
    "Increase Player Damage",
    "Increase Player Speed",
    "Add Ballista Tower",
  ];

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Logowanie rozmiaru ekranu
    print('Screen size: ${size.x}x${size.y}');

    final double spawnWidth = slotSize * 2; // Szerokość spawn area
    final double spawnHeight = slotSize; // Wysokość spawn area (opcjonalnie)

    final double spawnLeft =
        (size.x - spawnWidth) / 2; // Centrowanie na szerokości
    final double spawnTop = 0; // Pozycja na górze ekranu

    spawnAreaRect = Rect.fromLTWH(spawnLeft, spawnTop, spawnWidth, spawnHeight);
    print('Spawn Area: $spawnAreaRect');

    // Opcjonalnie: Wizualizacja obszaru spawnów dla debugowania
    add(RectangleComponent(
      position: Vector2(spawnAreaRect.left, spawnAreaRect.top),
      size: Vector2(spawnAreaRect.width, spawnAreaRect.height),
      paint: Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.fill,
    ));

    // Sprawdzenie, czy gridSize * slotSize nie przekracza wysokości ekranu
    if (gridSize * slotSize > size.y) {
      print(
          "Warning: gridSize * slotSize ($gridSize * $slotSize = ${gridSize * slotSize}) exceeds screen height (${size.y})");
    }

    // Ustaw kamerę na centralny widok
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(size.x, size.y),
    );

    // Dodanie tła
    final background = SpriteComponent()
      ..sprite = await loadSprite('background.png')
      ..size = size;
    add(background);

    _startNextWave();

    // Dodanie slotów wież
    _initializeTowerSlots();

    // Dodanie gracza
    player = Player();
    add(player);

    // Dodanie joysticka
    final joystick = CustomJoystick(
      onMove: (Vector2 direction) {
        player.setDirection(direction);
      },
      onStop: () {
        player.stop();
      },
    );
    add(joystick);

    // Dodanie HUD
    hudComponent = HudComponent(gameRef: this);
    add(hudComponent);

    // Dodanie nakładek
    _registerOverlays();

    // Start gry
    pauseGame();
    _showCardSelection();
  }

  void _registerOverlays() {
    overlays.addEntry(
      'GameOverOverlay',
      (BuildContext context, Game gameRef) =>
          GameOverOverlay(gameRef: gameRef as MyGame),
    );

    overlays.addEntry(
      'WinOverlay',
      (BuildContext context, Game gameRef) =>
          WinOverlay(gameRef: gameRef as MyGame),
    );

    overlays.addEntry(
      'CardSelection',
      (BuildContext context, Game gameRef) => CardSelectionOverlay(
        game: gameRef as MyGame,
      ),
    );
  }

  void _initializeTowerSlots() {
    final double pathHeight =
        size.y * 0.25; // Górne 25% zarezerwowane dla ścieżki wrogów
    final double towerAreaHeight =
        size.y - pathHeight; // Dolne 75% dla wieżyczek

    final int rows = (towerAreaHeight / slotSize).floor() - 1;
    final int cols = (size.x / slotSize).ceil();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final double x = col * slotSize;
        final double y = pathHeight + row * slotSize;

        // Dodanie slotu na siatkę
        final slot = TowerSlot(position: Vector2(x, y), row: row, col: col);
        add(slot);

        // Aktualizacja siatki, aby początkowo sloty były wolne
        updateGrid(row, col, false);
      }
    }
  }

  void reset() {
    currentWave = 1;
    remainingEnemies = 0;
    lives = 3;

    children.where((child) => child != hudComponent && child != player).forEach(
      (child) {
        child.removeFromParent();
      },
    );

    player.position = Vector2(50, 600);
    hudComponent.updateLives(lives);

    _startNextWave();
  }

  void gainExp(int exp) {
    currentExp += exp;

    if (currentExp >= nextLevelExp) {
      currentExp -= nextLevelExp;
      playerLevel++;
      nextLevelExp += 10;

      pauseGame();
      _showCardSelection();
    }

    hudComponent.updateExpBar(currentExp, nextLevelExp);
  }

  void _startNextWave() {
    if (currentWave > totalWaves) {
      _showWinMessage();
      return;
    }

    int enemiesForThisWave = baseEnemiesPerWave + (currentWave - 1) * 2;
    double enemyHealth = 20.0 * currentWave;

    remainingEnemies = enemiesForThisWave;

    for (int i = 0; i < enemiesForThisWave; i++) {
      final startPosition = _generateStartPosition();

      final enemy = Enemy(
        position: startPosition,
        healthPoints: enemyHealth,
      );

      enemy.onDefeated = _onEnemyDefeated;
      enemy.onReachBottom = _onEnemyReachBottom;

      add(enemy); // Dodanie przeciwnika do gry
      print('Enemy $i spawned at: $startPosition');
    }

    print('Total enemies added this wave: $enemiesForThisWave');

    currentWave++;
  }

  Vector2 _generateStartPosition() {
    final random = Random();
    Vector2 startPosition;
    bool validPosition = false;
    int attempts = 0;
    const int maxAttempts = 10;

    while (!validPosition && attempts < maxAttempts) {
      attempts++;
      // Generuj losową pozycję w ramach obszaru spawnów
      final double spawnX =
          spawnAreaRect.left + random.nextDouble() * spawnAreaRect.width;
      final double spawnY =
          spawnAreaRect.top + random.nextDouble() * spawnAreaRect.height;

      startPosition = Vector2(spawnX, spawnY);

      // Sprawdź odległość od istniejących wrogów
      bool tooClose = children.whereType<Enemy>().any((enemy) {
        return (enemy.position - startPosition).length <
            50; // Minimalna odległość
      });

      if (!tooClose) {
        validPosition = true;
        print('Valid spawn position found: $startPosition');
        return startPosition;
      }
    }

    // Jeśli nie znaleziono odpowiedniej pozycji po maxAttempts, zwróć losową pozycję
    final double fallbackX =
        spawnAreaRect.left + random.nextDouble() * spawnAreaRect.width;
    final double fallbackY =
        spawnAreaRect.top + random.nextDouble() * spawnAreaRect.height;

    final Vector2 fallbackPosition = Vector2(fallbackX, fallbackY);
    print('Fallback spawn position: $fallbackPosition');
    return fallbackPosition;
  }

  void _onEnemyReachBottom() {
    lives--;
    hudComponent.updateLives(lives);

    print('Enemy reached bottom! Lives remaining: $lives');

    if (lives <= 0) {
      _showGameOverMessage();
      return;
    }

    remainingEnemies--;
    _checkWaveCompletion();
  }

  void _onEnemyDefeated() {
    remainingEnemies--;
    gainExp(10);
    _checkWaveCompletion();
  }

  void _checkWaveCompletion() {
    if (remainingEnemies <= 0) {
      _startNextWave();
    }
  }

  void _showWinMessage() {
    overlays.add('WinOverlay');
    pauseEngine();
  }

  void _showGameOverMessage() {
    overlays.add('GameOverOverlay');
    pauseEngine();
  }

  void _showCardSelection() {
    pauseGame();
    overlays.add('CardSelection');
  }

  void pauseGame() {
    if (!isPaused) {
      pauseEngine();
      isPaused = true;
    }
  }

  void resumeGame() {
    if (isPaused) {
      resumeEngine();
      isPaused = false;
    }
  }

  void handleCardSelection(String card) {
    if (card.contains("Tower")) {
      // Dodanie wieży do wybranych kart
      selectedCards.add(card);
    } else if (card == "Increase Player Damage") {
      // Zwiększenie obrażeń gracza
      player.damage += 10;
    } else if (card == "Increase Player Speed") {
      // Zwiększenie prędkości gracza
      player.speed += 50;
    }

    // Usuń nakładkę wyboru kart
    overlays.remove('CardSelection');
    resumeGame(); // Wznowienie gry

    // Jeśli nie ma już przeciwników, rozpocznij nową falę
    if (remainingEnemies <= 0) {
      _startNextWave();
    }
  }

  List<Node> findPath(int startRow, int startCol, int endRow, int endCol) {
    final Map<String, List<Node>> pathCache = {};
    String key = '$startRow,$startCol-$endRow,$endCol';
    if (pathCache.containsKey(key)) {
      return pathCache[key]!;
    }
    List<Node> openList = [];
    List<Node> closedList = [];

    Node startNode = Node(startRow, startCol);
    Node endNode = Node(endRow, endCol);

    openList.add(startNode);

    while (openList.isNotEmpty) {
      // Znajdź node z najmniejszym fCost
      openList.sort((a, b) => a.fCost.compareTo(b.fCost));
      Node currentNode = openList.first;

      if (currentNode.row == endNode.row && currentNode.col == endNode.col) {
        // Odtwórz ścieżkę
        List<Node> path = [];
        Node? temp = currentNode;
        while (temp != null) {
          path.add(temp);
          temp = temp.parent;
        }
        return path.reversed.toList();
      }

      openList.remove(currentNode);
      closedList.add(currentNode);

      // Sprawdź sąsiadów (4 kierunki: góra, dół, lewo, prawo)
      List<Node> neighbors = [];
      List<List<int>> directions = [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1],
      ];

      for (var direction in directions) {
        int newRow = currentNode.row + direction[0];
        int newCol = currentNode.col + direction[1];

        // Sprawdź granice
        if (newRow < 0 ||
            newRow >= gridSize ||
            newCol < 0 ||
            newCol >= gridSize) {
          continue;
        }

        // Sprawdź, czy pole jest zajęte
        if (grid[newRow][newCol]) {
          continue;
        }

        neighbors.add(Node(newRow, newCol));
      }

      for (var neighbor in neighbors) {
        if (closedList.any(
            (node) => node.row == neighbor.row && node.col == neighbor.col)) {
          continue;
        }

        double tentativeGCost = currentNode.gCost + 1; // Koszt ruchu to 1

        Node? openNode = openList.firstWhere(
          (node) => node.row == neighbor.row && node.col == neighbor.col,
          orElse: () => Node(-1, -1),
        );

        if (openNode.row == -1 && openNode.col == -1) {
          neighbor.gCost = tentativeGCost;
          neighbor.hCost = (endNode.row - neighbor.row).abs() +
              (endNode.col - neighbor.col).abs().toDouble();
          neighbor.parent = currentNode;
          openList.add(neighbor);
        } else if (tentativeGCost < openNode.gCost) {
          openNode.gCost = tentativeGCost;
          openNode.parent = currentNode;
        }
      }
    }

    // Jeśli nie ma ścieżki, zwróć pustą listę
    return [];
  }

  Vector2 positionToGridIndices(Vector2 position) {
    // Uwzględnij przesunięcie ścieżki
    final double pathHeight = size.y * 0.25;
    int col = (position.x / slotSize).floor();
    int row = ((position.y - pathHeight) / slotSize).floor();

    // Upewnij się, że indeksy są w granicach siatki
    row = row.clamp(0, gridSize - 1);
    col = col.clamp(0, gridSize - 1);

    return Vector2(row.toDouble(), col.toDouble());
  }

  void updateEnemyPaths() {
    children.whereType<Enemy>().forEach((enemy) {
      enemy.calculatePath();
    });
  }
}

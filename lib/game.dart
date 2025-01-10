// Aktualizacja pliku game.dart

import 'dart:developer';
import 'dart:math' as math;

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:underworld_game/components/enemy/spawnPoint.dart';
import 'package:underworld_game/components/gameBoundries.dart';
import 'package:underworld_game/models/enemy.dart';
import 'package:underworld_game/models/player.dart';
import 'package:underworld_game/components/joystick.dart';
import 'package:underworld_game/components/tower_slot.dart';
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
  late Rect gameBounds = Rect.zero;
  final List<SpawnPoint> spawnPoints = [];
  final List<PositionComponent> obstacles = [];

  static const double slotSize = 80.0; // Rozmiar jednego slotu

  final List<String> availableCards = [
    "Increase Player Damage",
    "Increase Player Speed",
    "Add Ballista Tower",
  ];

  @override
  Future<void> onLoad() async {
    super.onLoad();
// Ustawienia granic gry
    const double boundaryMargin = 50.0; // Odstęp od prawej i lewej strony
    final gameWidth = size.x - 2 * boundaryMargin; // Szerokość obszaru gry
    final gameHeight = size.y; // Wysokość obszaru gry

    final gameBounds = GameBounds(
      Vector2(boundaryMargin, 0), // Pozycja granic
      Vector2(gameWidth, gameHeight), // Rozmiar granic
    );

    add(gameBounds); // Dodanie widocznych granic
    // Dodanie obszaru gry

    // Ustawienie granic gry
    log('Screen size: ${size.x}x${size.y}');
    _initializeEdgeCollisions();

    // Inicjalizacja obszaru spawn
    const double spawnWidth = slotSize * 2; // Szerokość spawn area
    const double spawnHeight = slotSize; // Wysokość spawn area

    final double spawnLeft =
        (size.x - spawnWidth) / 2; // Centrowanie na szerokości
    const double spawnTop = 0; // Pozycja na górze ekranu

    spawnAreaRect = Rect.fromLTWH(spawnLeft, spawnTop, spawnWidth, spawnHeight);
    log('Spawn Area: $spawnAreaRect');

    // Dodanie punktów spawn jako komponentów
    spawnPoints.addAll([
      SpawnPoint(Vector2(size.x / 4, 0)), // Punkt na górze, z lewej strony
      SpawnPoint(Vector2(size.x / 2, 0)), // Punkt centralny na górze
      SpawnPoint(Vector2(3 * size.x / 4, 0)), // Punkt na górze, z prawej strony
    ]);
    for (final spawnPoint in spawnPoints) {
      add(spawnPoint);
    }

    // Konfiguracja kamery
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(size.x, size.y),
    );

    // Dodanie tła
    final background = SpriteComponent()
      ..sprite = await loadSprite('background.png')
      ..size = size;
    add(background);

    // Uruchomienie pierwszej fali przeciwników
    _startNextWave();

    // Inicjalizacja slotów dla wież
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

    // Rejestracja nakładek
    _registerOverlays();

    // Pauza gry i pokazanie selekcji kart
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
    final double pathHeight = size.y * 0.25;
    final double towerAreaHeight = size.y - pathHeight;

    final int rows = (towerAreaHeight / slotSize).floor() - 1;
    final int cols = (size.x / slotSize).ceil();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final double x = col * slotSize;
        final double y = pathHeight + row * slotSize;

        final slot = TowerSlot(
            position: Vector2(x, y), row: row, col: col, isOccupied: false);
        add(slot);
      }
    }
  }

  void _startNextWave() async {
    if (currentWave > totalWaves) {
      _showWinMessage();
      return;
    }

    int enemiesForThisWave = baseEnemiesPerWave + (currentWave - 1) * 2;
    double enemyHealth = 20.0 * currentWave;

    remainingEnemies = enemiesForThisWave;

    for (int i = 0; i < enemiesForThisWave; i++) {
      await Future.delayed(const Duration(milliseconds: 500));

      final startPosition = _generateStartPosition();

      final enemy = Enemy(
        position: startPosition,
        healthPoints: enemyHealth,
      );

      enemy.onDefeated = _onEnemyDefeated;
      enemy.onReachBottom = _onEnemyReachBottom;

      add(enemy);
    }

    log('Total enemies added this wave: $enemiesForThisWave');
    currentWave++;
  }

  Vector2 _generateStartPosition() {
    final random = math.Random();

    // Wybieranie losowego punktu spawnu
    final spawnPoint = spawnPoints[random.nextInt(spawnPoints.length)];

    return spawnPoint.position.clone();
  }

  void _onEnemyReachBottom() {
    lives--;
    hudComponent.updateLives(lives);

    if (lives <= 0) {
      _showGameOverMessage();
      return;
    }

    remainingEnemies--;
    checkWaveCompletion();
  }

  void _onEnemyDefeated() {
    remainingEnemies--;
    gainExp(10);
    checkWaveCompletion();
  }

  void checkWaveCompletion() {
    if (remainingEnemies <= 0) {
      log('Wave $currentWave completed. Starting next wave in 5 seconds...');

      int countdown = 5;
      hudComponent.updateWaveTimer(countdown);

      void tick() {
        if (countdown > 0) {
          countdown--;
          hudComponent.updateWaveTimer(countdown);

          Future.delayed(const Duration(seconds: 1), tick);
        } else {
          hudComponent.clearWaveTimer();
          _startNextWave();
        }
      }

      tick();
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

  void _initializeEdgeCollisions() {
    log('Game boundaries initialized.');
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

  void reset() {
    currentWave = 1;
    remainingEnemies = 0;
    lives = 3;

    // Usuwanie wszystkich elementów gry z wyjątkiem HUD i gracza
    children.where((child) => child != hudComponent && child != player).forEach(
      (child) {
        child.removeFromParent();
      },
    );

    // Resetowanie pozycji gracza
    player.position = Vector2(50, 600);
    hudComponent.updateLives(lives);

    // Rozpoczęcie nowej fali
    _startNextWave();
  }

  void updateEnemyPaths() {
    final enemies = children.whereType<Enemy>().toList();
    for (final enemy in enemies) {
      enemy.calculatePath();
    }
  }

  void registerObstacle(PositionComponent obstacle) {
    obstacles.add(obstacle);
  }
}

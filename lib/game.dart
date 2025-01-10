// Aktualizacja pliku game.dart

import 'dart:developer';
import 'dart:math' as math;

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:underworld_game/components/play_area.dart';
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

  static const double slotSize = 80.0; // Rozmiar jednego slotu

  final List<String> availableCards = [
    "Increase Player Damage",
    "Increase Player Speed",
    "Add Ballista Tower",
  ];

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(PlayArea());

    gameBounds = Rect.fromLTWH(0, 0, size.x, size.y);
    log('Screen size: ${size.x}x${size.y}');
    _initializeEdgeCollisions();

    const double spawnWidth = slotSize * 2; // Szerokość spawn area
    const double spawnHeight = slotSize; // Wysokość spawn area

    final double spawnLeft =
        (size.x - spawnWidth) / 2; // Centrowanie na szerokości
    const double spawnTop = 0; // Pozycja na górze ekranu

    spawnAreaRect = Rect.fromLTWH(spawnLeft, spawnTop, spawnWidth, spawnHeight);
    log('Spawn Area: $spawnAreaRect');

    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(size.x, size.y),
    );

    final background = SpriteComponent()
      ..sprite = await loadSprite('background.png')
      ..size = size;
    add(background);

    _startNextWave();

    _initializeTowerSlots();

    player = Player();
    add(player);

    final joystick = CustomJoystick(
      onMove: (Vector2 direction) {
        player.setDirection(direction);
      },
      onStop: () {
        player.stop();
      },
    );
    add(joystick);

    hudComponent = HudComponent(gameRef: this);
    add(hudComponent);

    _registerOverlays();

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

        final slot = TowerSlot(position: Vector2(x, y), row: row, col: col);
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

    final double spawnX =
        spawnAreaRect.left + random.nextDouble() * spawnAreaRect.width;
    final double spawnY = spawnAreaRect.top + slotSize / 2;

    return Vector2(spawnX, spawnY);
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
}

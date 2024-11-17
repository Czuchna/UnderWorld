import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:underworld_game/components/card_selection.dart';
import 'package:underworld_game/components/enemy.dart';
import 'package:underworld_game/components/player.dart';
import 'package:underworld_game/components/joystick.dart';
import 'package:underworld_game/components/tower_slot.dart';
import 'package:underworld_game/widgets/card_selection_overlay.dart';
import 'package:underworld_game/widgets/gameover.dart';
import 'package:underworld_game/widgets/winoverlay.dart';
import 'package:underworld_game/components/hud.dart';

class MyGame extends FlameGame with HasCollisionDetection, DragCallbacks {
  late Player player;
  late HudComponent hudComponent;

  final List<String> selectedCards = [];
  int currentWave = 1;
  final int totalWaves = 5;
  final int baseEnemiesPerWave = 5;
  int remainingEnemies = 0;
  int lives = 3;
  int playerLevel = 1;
  int currentExp = 0;
  int nextLevelExp = 10;
  bool isPaused = false;

  final List<String> availableCards = [
    "Increase Player Damage",
    "Increase Player Speed",
    "Add Ballista Tower",
  ];

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Dodanie tła
    final background = SpriteComponent()
      ..sprite = await loadSprite('background.png')
      ..size = size;
    add(background);

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

    // Wyświetlenie wyboru kart i pauza na początku gry
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

  // Inicjalizacja slotów na wieże
  void _initializeTowerSlots() {
    final double topSafeZone = size.y * 0.25;
    final positions = [
      Vector2(100, topSafeZone + 100),
      Vector2(200, topSafeZone + 200),
      Vector2(300, topSafeZone + 300),
      Vector2(400, topSafeZone + 200),
    ];

    for (final position in positions) {
      final slot = TowerSlot(position: position);
      add(slot);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    camera.viewport =
        FixedResolutionViewport(resolution: Vector2(size.x, size.y));
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

  void _onEnemyDefeated() {
    remainingEnemies--;
    gainExp(2); // Dodaj EXP za pokonanie przeciwnika
    _checkWaveCompletion(); // Sprawdź, czy fala została ukończona
  }

  void _startNextWave() {
    print('Rozpoczynanie fali: $currentWave');
    print('Generowanie potworów...');
    // Jeśli osiągnięto maksymalną liczbę fal, wyświetl wiadomość o wygranej
    if (currentWave > totalWaves) {
      _showWinMessage();
      return;
    }

    // Oblicz liczbę i zdrowie przeciwników na bieżącą falę
    int enemiesForThisWave = baseEnemiesPerWave + (currentWave - 1) * 5;
    double enemyHealth = 20.0 * currentWave;

    remainingEnemies = enemiesForThisWave;
    for (int i = 0; i < enemiesForThisWave; i++) {
      final enemy = Enemy(
        position: _getRandomPosition(),
        healthPoints: enemyHealth,
      );
      enemy.onDefeated = _onEnemyDefeated;
      enemy.onReachBottom = _onEnemyReachBottom;
      add(enemy);
      print('Dodano potwora na pozycji: ${enemy.position}');
    }

    currentWave++;
  }

  void _onEnemyReachBottom() {
    lives--;
    hudComponent.updateLives(lives);

    if (lives <= 0) {
      _showGameOverMessage();
      return;
    }

    remainingEnemies--;
    _checkWaveCompletion();
  }

  void _checkWaveCompletion() {
    if (remainingEnemies <= 0) {
      print('Wszyscy wrogowie pokonani, uruchamianie nowej fali...');
      _startNextWave();
    }
  }

  void _showWinMessage() {
    Future.delayed(const Duration(milliseconds: 500), () {
      overlays.add('WinOverlay');
      pauseEngine();
    });
  }

  void _showGameOverMessage() {
    overlays.add('GameOverOverlay');
    pauseEngine();
  }

  void _showCardSelection() {
    pauseGame(); // Pauza gry podczas wyboru karty
    overlays.add('CardSelection'); // Dodaj nakładkę
  }

  void handleCardSelection(String card) {
    if (card.contains("Tower")) {
      selectedCards.add(card);
    } else if (card == "Increase Player Damage") {
      player.damage += 10;
    } else if (card == "Increase Player Speed") {
      player.speed += 50;
    }

    overlays.remove('CardSelection'); // Usuń nakładkę wyboru kart
    resumeGame(); // Wznów grę

    // Uruchom kolejną falę, jeśli brak przeciwników
    if (remainingEnemies <= 0) {
      print('Rozpoczęcie nowej fali po wyborze karty...');
      _startNextWave();
    }
  }

  void pauseGame() {
    pauseEngine();
    isPaused = true;
  }

  void resumeGame() {
    if (!isPaused) return;
    print('Gra wznowiona.');
    isPaused = false;
    resumeEngine();
    if (remainingEnemies == 0) {
      print('Rozpoczynam falę po wznowieniu.');
      _startNextWave();
    }
  }

  Vector2 _getRandomPosition() {
    final random = Random();
    final x = random.nextDouble() * (size.x - 50);
    final y = random.nextDouble() * (size.y * 0.3 - 50);
    return Vector2(x, y);
  }
}

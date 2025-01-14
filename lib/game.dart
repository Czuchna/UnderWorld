import 'dart:developer';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:underworld_game/models/enemy.dart';
import 'package:underworld_game/models/grid.dart';
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
  late Grid grid; // Centralna siatka gry
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
  List<TowerSlot> towerSlots = [];

  static const double slotSize = 80.0;

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

    // Inicjalizacja siatki
    _initializeGrid();

    // Dodanie granic gry
    _initializeGameBounds();

    // Inicjalizacja slotów dla wież
    initializeTowerSlots();

    // Dodanie gracza
    player = Player();
    add(player);

    // Dodanie joysticka
    _initializeJoystick();

    // Dodanie HUD
    hudComponent = HudComponent(gameRef: this);
    add(hudComponent);

    // Rejestracja nakładek
    _registerOverlays();
    _showCardSelection();
    // Uruchomienie pierwszej fali przeciwników
    _startNextWave();
  }

  void _initializeGrid() {
    final int rows = (size.y / slotSize).ceil();
    final int cols = (size.x / slotSize).ceil();
    grid = Grid(rows, cols);
    log('Grid initialized with $rows rows and $cols columns');

    // Centralna część siatki dla slotów wież
    final int towerGridRows = rows ~/ 2; // np. połowa siatki dla wież
    final int towerGridCols = cols; // Wszystkie kolumny
    final int offsetRow = (rows - towerGridRows) ~/ 2;

    log('Central tower grid: $towerGridRows rows x $towerGridCols cols');
    log('Offset: Row $offsetRow');

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final slotPosition = Vector2(col * slotSize, row * slotSize);

        // Dodanie wizualnej siatki gry
        final isCentralGrid =
            row >= offsetRow && row < offsetRow + towerGridRows;

        add(RectangleComponent(
          position: slotPosition,
          size: Vector2(slotSize, slotSize),
          paint: (Paint()
            ..color = isCentralGrid
                ? Colors.blue
                    .withOpacity(0.3) // Centralny obszar w innym kolorze
                : Colors.red.withOpacity(0.4) // Zewnętrzna siatka
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0),
        ));

        // Dodanie slotów wież w centralnym obszarze
        if (isCentralGrid) {
          final towerSlot = TowerSlot(
            isOccupied: false,
            row: row,
            col: col,
            position: slotPosition,
          );
          add(towerSlot);
          towerSlots.add(towerSlot);
        }
      }
    }
  }

  void _initializeGameBounds() {
    log('Screen size: ${size.x}x${size.y}');
    const double boundaryMargin =
        1.0; // Zmniejszone marginesy (więcej miejsca na granice)
    final gameWidth = size.x - 2 * boundaryMargin;
    final gameHeight = size.y;

    add(RectangleComponent(
      position: Vector2(boundaryMargin, 0),
      size: Vector2(gameWidth, gameHeight),
      paint: Paint()
        ..color =
            const Color(0xFF00FF00).withOpacity(0.7) // Widoczniejszy kolor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0, // Grubsza granica
    ));
    log('Game bounds initialized: Width = $gameWidth, Height = $gameHeight');
  }

  void initializeTowerSlots() {
    // Inicjalizacja slotów wież
    for (final slot in children.whereType<TowerSlot>()) {
      towerSlots.add(slot);
    }
  }

  List<Vector2> getOccupiedSlots() {
    return towerSlots
        .where((slot) => slot.isOccupied)
        .map((slot) => slot.position)
        .toList();
  }

  List<Vector2> getFreeSlots() {
    return towerSlots
        .where((slot) => !slot.isOccupied)
        .map((slot) => slot.position)
        .toList();
  }

  void _initializeJoystick() {
    final joystick = CustomJoystick(
      onMove: (Vector2 direction) {
        player.setDirection(direction);
      },
      onStop: () {
        player.stop();
      },
    );
    add(joystick);
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
    final spawnX = random.nextInt(grid.cols) * slotSize;
    return Vector2(spawnX.toDouble(), 0);
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

  void _onEnemyDefeated() {
    remainingEnemies--;
    gainExp(10);
    _checkWaveCompletion();
  }

  void _checkWaveCompletion() {
    if (remainingEnemies <= 0) {
      log('Wave $currentWave completed.');
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

  void gainExp(int exp) {
    currentExp += exp;

    if (currentExp >= nextLevelExp) {
      currentExp -= nextLevelExp;
      playerLevel++;
      nextLevelExp += 10;

      log('Player leveled up to level $playerLevel');
      _showCardSelection();
    }

    hudComponent.updateExpBar(currentExp, nextLevelExp);
  }

  void handleCardSelection(String card) {
    log('Card selected: $card');

    if (card.contains("Tower")) {
      // Logika dodania wieży
      selectedCards.add(card);
      log('Card added to selected cards: $card');
    } else if (card == "Increase Player Damage") {
      // Zwiększenie obrażeń gracza
      player.damage += 10;
      log('Player damage increased to ${player.damage}');
    } else if (card == "Increase Player Speed") {
      // Zwiększenie prędkości gracza
      player.speed += 50;
      log('Player speed increased to ${player.speed}');
    }

    // Usunięcie nakładki i wznowienie gry
    overlays.remove('CardSelection');
    resumeEngine();
  }

  void resumeGame() {
    if (isPaused) {
      resumeEngine(); // Wznawia działanie silnika gry
      isPaused = false;
      log('Game resumed.');
    }
  }

  void reset() {
    // Zresetuj falę i liczbę przeciwników
    currentWave = 1;
    remainingEnemies = 0;

    // Zresetuj liczbę żyć gracza
    lives = 3;

    // Usuń wszystkie komponenty gry (przeciwników, wieże itp.), poza HUD i graczem
    children.where((child) => child != hudComponent && child != player).forEach(
      (child) {
        child.removeFromParent();
      },
    );

    // Przywróć pozycję gracza
    player.position = Vector2(50, size.y - 100);

    // Zresetuj siatkę przeszkód
    for (int row = 0; row < grid.rows; row++) {
      for (int col = 0; col < grid.cols; col++) {
        grid.setOccupied(row, col, false);
      }
    }

    // Zresetuj pasek życia i inne elementy HUD
    hudComponent.updateLives(lives);

    // Rozpocznij nową grę
    _startNextWave();
  }

  void _showCardSelection() {
    log('Showing card selection overlay');
    pauseGame();
    overlays.add('CardSelection');
  }

  void pauseGame() {
    if (!isPaused) {
      pauseEngine(); // Wstrzymuje silnik gry
      isPaused = true;
      log('Game paused.');
    }
  }

  void updateEnemyPaths() {
    for (final enemy in children.whereType<Enemy>()) {
      enemy.calculatePath();
    }
  }
}

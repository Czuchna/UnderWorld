import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:underworld_game/models/enemy.dart';

class Player extends SpriteAnimationComponent
    with HasGameRef, CollisionCallbacks {
  Vector2 direction = Vector2.zero(); // Kierunek ruchu
  final double attackRange = 70; // Zasięg ataku
  final double attackInterval = 0.4; // Odstęp między atakami
  late Timer attackTimer;

  double speed; // Prędkość gracza
  double damage; // Obrażenia zadawane przez gracza

  late SpriteAnimation idleAnimation; // Animacja bezczynności
  late SpriteAnimation runAnimation; // Animacja biegania
  late SpriteAnimation attackAnimation; // Animacja ataku
  bool isAttacking = false;

  final Set<Enemy> attackedEnemies =
      {}; // Przeciwnicy zaatakowani w bieżącym cyklu

  Player({this.speed = 200.0, this.damage = 10.0})
      : super(
          size: Vector2(100, 100),
          position: Vector2(50, 600),
        ) {
    attackTimer = Timer(attackInterval, repeat: true, onTick: _attackEnemies);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Animacja biegania
    runAnimation = SpriteAnimation.spriteList(
      [
        await gameRef.loadSprite('animations/Run_000.png'),
        await gameRef.loadSprite('animations/Run_001.png'),
        await gameRef.loadSprite('animations/Run_002.png'),
        await gameRef.loadSprite('animations/Run_003.png'),
        await gameRef.loadSprite('animations/Run_004.png'),
        await gameRef.loadSprite('animations/Run_005.png'),
        await gameRef.loadSprite('animations/Run_006.png'),
        await gameRef.loadSprite('animations/Run_007.png'),
        await gameRef.loadSprite('animations/Run_008.png'),
        await gameRef.loadSprite('animations/Run_009.png'),
      ],
      stepTime: 0.1,
      loop: true,
    );

    // Animacja ataku
    attackAnimation = SpriteAnimation.spriteList(
      [
        await gameRef.loadSprite('animations/Attack_000.png'),
        await gameRef.loadSprite('animations/Attack_001.png'),
        await gameRef.loadSprite('animations/Attack_002.png'),
        await gameRef.loadSprite('animations/Attack_003.png'),
        await gameRef.loadSprite('animations/Attack_004.png'),
      ],
      stepTime: 0.1,
      loop: false,
    );

    // Animacja bezczynności
    idleAnimation = runAnimation;

    // Początkowa animacja
    animation = idleAnimation;

    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Poruszaj postacią
    position += direction.normalized() * speed * dt;

    // Ogranicz pozycję gracza do granic ekranu
    position.clamp(
      Vector2(0, 0),
      Vector2(gameRef.size.x - size.x, gameRef.size.y - size.y),
    );

    // Zmień animację w zależności od ruchu
    if (!isAttacking) {
      if (direction != Vector2.zero()) {
        animation = runAnimation;
      } else {
        animation = idleAnimation;
      }
    }

    attackTimer.update(dt);
  }

  void setDirection(Vector2 newDirection) {
    direction = newDirection;
  }

  void stop() {
    direction = Vector2.zero();
  }

  void _attackEnemies() {
    final enemies = gameRef.children.whereType<Enemy>();
    final List<Enemy> enemiesInRange = [];

    for (final enemy in enemies) {
      if (enemy.position.distanceTo(position) <= attackRange) {
        // Upewnij się, że przeciwnik nie został już zaatakowany w tej turze
        if (!attackedEnemies.contains(enemy)) {
          attackedEnemies.add(enemy); // Dodaj przeciwnika do zaatakowanych
          enemiesInRange.add(enemy);
        }
      }
    }

    if (enemiesInRange.isNotEmpty) {
      for (final enemy in enemiesInRange) {
        enemy.takeDamage(damage); // Zadaj obrażenia
        _showDamage(enemy, damage); // Wyświetl obrażenia
        print(
            'Zadałem obrażenia: $damage, Przeciwnik ma teraz HP: ${enemy.healthPoints}');
      }
      _startAttack();
    }

    // Zresetuj listę zaatakowanych przeciwników po `attackInterval`
    Future.delayed(Duration(milliseconds: (attackInterval * 1000).toInt()), () {
      attackedEnemies.clear();
    });
  }

  void _startAttack() {
    if (isAttacking) return;
    isAttacking = true;

    animation = attackAnimation;

    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        isAttacking = false;
      },
    );
  }

  void _showDamage(Enemy enemy, double damage) {
    final damageText = TextComponent(
      text: '-${damage.toInt()}❤️',
      position: enemy.position.clone()..y -= 20,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.red,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    gameRef.add(damageText);

    Future.delayed(const Duration(milliseconds: 500), () {
      damageText.removeFromParent();
    });
  }

  void increaseDamage(double value) {
    damage += value;
    print("Player damage increased to $damage");
  }

  void increaseSpeed(double value) {
    speed += value;
    print("Player speed increased to $speed");
  }
}

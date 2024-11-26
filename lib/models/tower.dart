import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:underworld_game/models/enemy.dart';

class Tower extends SpriteComponent with HasGameRef {
  final double attackRange;
  final double attackDamage;
  final double attackInterval;
  late Timer attackTimer;

  Tower({
    required Vector2 position,
    required this.attackRange,
    required this.attackDamage,
    required this.attackInterval,
  }) : super(
          position: position,
          size: Vector2(80, 80),
        ) {
    attackTimer = Timer(attackInterval, repeat: true, onTick: _attackEnemies);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    sprite = await gameRef.loadSprite('ballista.png');
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    attackTimer.update(dt);
  }

  void _attackEnemies() {
    final enemiesInRange = gameRef.children.whereType<Enemy>().where((enemy) {
      return enemy.position.distanceTo(position) <= attackRange;
    }).toList();

    if (enemiesInRange.isNotEmpty) {
      // Załóżmy, że wieża atakuje pierwszego wroga w zasięgu
      final enemy = enemiesInRange.first;
      enemy.takeDamage(attackDamage);
      print("Tower attacked an enemy for $attackDamage damage!");
    }
  }
}

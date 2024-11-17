import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

class Enemy extends SpriteComponent with HasGameRef, CollisionCallbacks {
  double healthPoints; // Current health points of the enemy
  final double maxHealthPoints; // Maximum health points
  final double speed = 50; // Speed of the enemy's movement
  Function()?
      onReachBottom; // Called when the enemy reaches the bottom of the screen
  VoidCallback? onDefeated; // Called when the enemy is defeated

  late RectangleComponent healthBar; // Health bar
  late RectangleComponent healthBarBackground; // Background of the health bar

  Enemy({
    required Vector2 position,
    required this.healthPoints, // Set initial health points
  })  : maxHealthPoints = healthPoints, // Set maximum health points
        super(
          position: position,
          size: Vector2(70, 70), // Size of the enemy
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Load the sprite for the enemy
    sprite = await gameRef.loadSprite('enemy.png');
    add(RectangleHitbox()); // Add collision detection

    // Add background for the health bar
    healthBarBackground = RectangleComponent(
      position: Vector2(0, -10), // Positioned just above the enemy
      size: Vector2(size.x, 5), // Same width as the enemy
      paint: Paint()..color = Colors.grey, // Grey background color
    );
    add(healthBarBackground);

    // Add health bar
    healthBar = RectangleComponent(
      position: Vector2(0, -10), // Positioned just above the enemy
      size: Vector2(size.x, 5), // Same width as the enemy
      paint: Paint()..color = Colors.red, // Red color for the health bar
    );
    add(healthBar);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move the enemy downwards
    position.y += speed * dt;

    // Check if the enemy has reached the bottom of the screen
    if (position.y > gameRef.size.y) {
      onReachBottom?.call(); // Trigger the bottom reach event
      removeFromParent(); // Remove the enemy
    }

    // Clamp the position to the screen boundaries
    position.clamp(
      Vector2(0, 0),
      Vector2(gameRef.size.x - size.x, gameRef.size.y),
    );
  }

  // Method to deal damage to the enemy
  void takeDamage(double damage) {
    healthPoints -= damage;

    // Update the size of the health bar
    healthBar.size.x = (healthPoints / maxHealthPoints) * size.x;

    if (healthPoints <= 0) {
      if (onDefeated != null) {
        onDefeated!(); // Notify about the enemy being defeated
      }
      removeFromParent(); // Remove the enemy from the game
    }
  }

  @override
  void onRemove() {
    super.onRemove();
    print("Enemy removed: Health was $healthPoints");
  }
}

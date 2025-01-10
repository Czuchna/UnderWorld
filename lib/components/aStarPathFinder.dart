import 'dart:developer';

import 'package:flame/components.dart';
import 'package:flutter/rendering.dart';

class AStarPathfinder {
  final List<RectangleComponent> obstacles;
  final Vector2 gridSize;

  AStarPathfinder({required this.obstacles, required this.gridSize});

  List<Vector2> findPath(Vector2 start, Vector2 target) {
    final openList = <Vector2>[start];
    final cameFrom = <Vector2, Vector2>{};
    final gScore = <Vector2, double>{start: 0};
    final fScore = <Vector2, double>{start: start.distanceTo(target)};

    while (openList.isNotEmpty) {
      openList.sort((a, b) => fScore[a]!.compareTo(fScore[b]!));
      final current = openList.removeAt(0);
      if ((current - target).length < 5.0) {
        return _reconstructPath(cameFrom, current);
      }

      for (final neighbor in _getNeighbors(current)) {
        if (_isObstacle(neighbor)) continue;

        final tentativeGScore = gScore[current]! + current.distanceTo(neighbor);

        if (tentativeGScore < (gScore[neighbor] ?? double.infinity)) {
          cameFrom[neighbor] = current;
          gScore[neighbor] = tentativeGScore;
          fScore[neighbor] = tentativeGScore + neighbor.distanceTo(target);

          if (!openList.contains(neighbor)) {
            openList.add(neighbor);
          }
        }
      }
    }

    return [];
  }

  List<Vector2> _getNeighbors(Vector2 node) {
    final neighbors = <Vector2>[
      Vector2(node.x - 10, node.y),
      Vector2(node.x + 10, node.y),
      Vector2(node.x, node.y - 10),
      Vector2(node.x, node.y + 10),
    ];
    return neighbors.where((neighbor) => _isWithinBounds(neighbor)).toList();
  }

  bool _isWithinBounds(Vector2 point) {
    return point.x >= 0 &&
        point.y >= 0 &&
        point.x <= gridSize.x &&
        point.y <= gridSize.y;
  }

  bool _isObstacle(Vector2 point) {
    for (final obstacle in obstacles) {
      final rect = obstacle
          .toRect(); // Usuń inflate, aby zobaczyć faktyczne obszary przeszkód
      log('Checking point $point against obstacle $rect');
      if (rect.contains(Offset(point.x, point.y))) {
        log('Point $point is within obstacle $rect');
        return true;
      }
    }
    return false;
  }

  List<Vector2> _reconstructPath(
      Map<Vector2, Vector2> cameFrom, Vector2 current) {
    final path = <Vector2>[current];
    while (cameFrom.containsKey(current)) {
      current = cameFrom[current]!;
      path.add(current);
    }
    return path.reversed.toList();
  }
}

import 'dart:developer';

import 'package:flame/components.dart';
import 'package:underworld_game/models/grid.dart';

class AStarPathfinder {
  final Grid grid;
  final Map<String, bool> obstacleMap;

  AStarPathfinder({
    required this.grid,
    required this.obstacleMap,
  });

  List<Vector2> findPath(Vector2 start, Vector2 target) {
    log('Finding path from $start to $target');

    start = _alignToGrid(start);
    target = _alignToGrid(target);

    if (_isObstacle(start)) {
      log('Start position $start is within an obstacle!');
      return [];
    }

    if (_isObstacle(target)) {
      log('Target position $target is within an obstacle!');
      return [];
    }

    final openList = <Vector2>[start];
    final cameFrom = <Vector2, Vector2>{};
    final gScore = <Vector2, double>{start: 0};
    final fScore = <Vector2, double>{start: start.distanceTo(target)};

    while (openList.isNotEmpty) {
      openList.sort((a, b) => (fScore[a] ?? double.infinity)
          .compareTo(fScore[b] ?? double.infinity));
      final current = openList.removeAt(0);

      if ((current - target).length < 5.0) {
        log('Target reached at $current');
        return _reconstructPath(cameFrom, current);
      }

      for (final neighbor in _getNeighbors(current)) {
        if (_isObstacle(neighbor)) {
          continue;
        }

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

    log('No valid path found from $start to $target');
    return [];
  }

  List<Vector2> _getNeighbors(Vector2 node) {
    final neighbors = <Vector2>[
      Vector2(node.x - 80, node.y),
      Vector2(node.x + 80, node.y),
      Vector2(node.x, node.y - 80),
      Vector2(node.x, node.y + 80),
    ];

    return neighbors.where((neighbor) {
      final col = (neighbor.x / 80).floor();
      final row = (neighbor.y / 80).floor();
      final withinBounds =
          col >= 0 && row >= 0 && col < grid.cols && row < grid.rows;

      return withinBounds && !_isObstacle(neighbor);
    }).toList();
  }

  bool _isObstacle(Vector2 point) {
    final col = (point.x / 80).floor();
    final row = (point.y / 80).floor();
    final key = '$col,$row';

    final isObstacle = obstacleMap[key] ?? false;
    log('Point $point maps to [$col, $row] and isObstacle: $isObstacle');
    return isObstacle;
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

  Vector2 _alignToGrid(Vector2 point) {
    final alignedX = (point.x / 80).floor() * 80.0;
    final alignedY = (point.y / 80).floor() * 80.0;
    return Vector2(alignedX, alignedY);
  }
}

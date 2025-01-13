class Grid {
  final int rows;
  final int cols;
  final List<List<bool>> grid;

  Grid(this.rows, this.cols)
      : grid = List.generate(rows, (_) => List.filled(cols, false));

  bool isOccupied(int row, int col) {
    if (row < 0 || col < 0 || row >= rows || col >= cols) {
      return true; // Blokada na granicach
    }
    return grid[row][col];
  }

  void setOccupied(int row, int col, bool occupied) {
    if (row >= 0 && col >= 0 && row < rows && col < cols) {
      grid[row][col] = occupied;
    }
  }

  Map<String, bool> toObstacleMap() {
    final Map<String, bool> obstacleMap = {};

    for (int y = 0; y < grid.length; y++) {
      for (int x = 0; x < grid[y].length; x++) {
        obstacleMap['$x,$y'] = grid[y][x];
      }
    }

    return obstacleMap;
  }
}

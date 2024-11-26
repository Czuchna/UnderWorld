class Node {
  final int row;
  final int col;
  double gCost = 0; // Koszt od startu
  double hCost = 0; // Heurystyka do celu
  double get fCost => gCost + hCost;
  Node? parent;

  Node(this.row, this.col);
}

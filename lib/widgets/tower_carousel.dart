import 'package:flutter/material.dart';

class TowerCarousel extends StatelessWidget {
  final List<String> towers;
  final Function(String) onTowerSelected;

  const TowerCarousel(
      {super.key, required this.towers, required this.onTowerSelected});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 100,
        color: Colors.black.withOpacity(0.5),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: towers.length,
          itemBuilder: (context, index) {
            final tower = towers[index];
            return Draggable<String>(
              data: tower,
              feedback: _buildDraggableCard(tower),
              childWhenDragging: _buildDraggableCard(tower, isDragging: true),
              child: _buildDraggableCard(tower),
              onDragStarted: () => print('Dragging started for $tower'),
              onDragCompleted: () => print('Dragging completed for $tower'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDraggableCard(String tower, {bool isDragging = false}) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDragging ? Colors.grey : Colors.blue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          tower,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class CustomJoystick extends Component with DragCallbacks {
  final Function(Vector2) onMove;
  final VoidCallback onStop;

  late CircleComponent knob;
  late CircleComponent background;
  bool isDragging = false;

  CustomJoystick({
    required this.onMove,
    required this.onStop,
  });

  @override
  int get priority => 100; // Wyższy priorytet niż sloty czy inne komponenty

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Tło joysticka
    background = CircleComponent(
      radius: 50,
      paint: Paint()..color = const Color.fromARGB(100, 0, 0, 0),
    );

    // Gałka joysticka
    knob = CircleComponent(
      radius: 20,
      paint: Paint()..color = const Color.fromARGB(180, 255, 255, 255),
    );

    add(background);
    add(knob);

    // Początkowa pozycja joysticka
    hideJoystick();
  }

  void hideJoystick() {
    background.position = Vector2(-100, -100); // Poza ekranem
    knob.position = Vector2(-100, -100); // Poza ekranem
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return true;
  }

  @override
  bool onDragStart(DragStartEvent event) {
    super.onDragStart(event);

    // Pokaż joystick w miejscu dotknięcia
    background.position = event.localPosition - Vector2.all(50);
    knob.position = event.localPosition - Vector2.all(20);
    isDragging = true;
    return true;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    if (!isDragging) return false;

    final direction = (event.localPosition - background.center).normalized();
    final distance = (event.localPosition - background.center).length;

    if (distance <= background.radius) {
      knob.position = event.localPosition - Vector2.all(20);
    } else {
      knob.position =
          background.center + direction * background.radius - Vector2.all(20);
    }

    onMove(direction);
    return true;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    hideJoystick();
    isDragging = false;
    onStop();
    return true;
  }
}

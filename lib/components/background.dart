import 'package:flame/components.dart';

class Background extends SpriteComponent with HasGameRef {
  Background();

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Załaduj obraz tła
    sprite = await Sprite.load('background.png');

    // Dopasuj rozmiar tła do rozmiaru ekranu gry
    size = gameRef.size;
  }
}

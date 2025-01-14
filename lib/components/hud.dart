import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class HudComponent extends PositionComponent {
  final FlameGame gameRef;
  late TextComponent livesText;
  int maxLives = 3; // Maksymalna liczba żyć
  late Rect expBarBackground;
  late Rect expBarForeground;
  late Paint expBarBgPaint;
  late Paint expBarFgPaint;
  late TextComponent waveTimerText;

  HudComponent({required this.gameRef}) : super(priority: 10);

  @override
  Future<void> onLoad() async {
    super.onLoad();

// Inicjalizacja tekstu licznika
    waveTimerText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 32, // Większy rozmiar czcionki
          color: Colors.white,
          fontWeight: FontWeight.bold, // Pogrubienie dla lepszej widoczności
        ),
      ),
    );

    // Umieść licznik na środku górnej części ekranu
    waveTimerText.anchor =
        Anchor.center; // Ustawienie punktu zaczepienia na środek
    waveTimerText.position = Vector2(
      gameRef.size.x / 2, // Środek w poziomie
      120, // Odległość od góry
    );

    add(waveTimerText); // Dodanie komponentu do HUD

    // Wysokość status bara
    final double statusBarHeight = MediaQueryData.fromView(
      WidgetsBinding.instance.platformDispatcher.views.first,
    ).padding.top;

    // Pasek doświadczenia
    final barWidth = gameRef.size.x - 20;
    expBarBackground = Rect.fromLTWH(10, statusBarHeight + 10, barWidth, 20);
    expBarForeground = Rect.fromLTWH(10, statusBarHeight + 10, 0, 20);

    expBarBgPaint = Paint()..color = Colors.grey.withOpacity(0.5);
    expBarFgPaint = Paint()..color = Colors.yellow.withOpacity(0.8);

    // Dodanie liczby żyć, przesunięcie poniżej paska doświadczenia
    livesText = TextComponent(
      text: "❤❤❤",
      position: Vector2(10, statusBarHeight + 40), // Zwiększamy wysokość
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    add(livesText);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Renderowanie paska EXP
    canvas.drawRect(expBarBackground, expBarBgPaint);
    canvas.drawRect(expBarForeground, expBarFgPaint);
  }

  void updateExpBar(int currentExp, int nextLevelExp) {
    final progress = currentExp / nextLevelExp;
    expBarForeground = Rect.fromLTWH(
      expBarBackground.left,
      expBarBackground.top,
      expBarBackground.width * progress,
      expBarBackground.height,
    );
  }

  // Funkcja do generowania tekstu z sercami
  String _generateLivesText(int lives) {
    String activeHearts = "❤️" * lives; // Czerwone serca (życia)
    String inactiveHearts =
        "🖤" * (maxLives - lives); // Szare serca (brakujące życia)
    return activeHearts + inactiveHearts; // Połączone serca
  }

  // Aktualizacja liczby żyć
  void updateLives(int lives) {
    livesText.text = _generateLivesText(lives); // Aktualizacja tekstu
  }

  void updateWaveTimer(int seconds) {
    waveTimerText.text =
        '0:${seconds.toString().padLeft(2, '0')}s'; // Aktualizacja tekstu
  }

  void clearWaveTimer() {
    waveTimerText.text = ''; // Ukrycie licznika przez ustawienie pustego tekstu
  }
}

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:underworld_game/router.dart';

@RoutePage()
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    // Symuluj ładowanie zasobów
    for (int i = 1; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 30), () {
        setState(() {
          _progress = i / 100;
        });
      });
    }

    if (mounted) {
      context.router.replace(const MainMenuRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Tło
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Pasek ładowania
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Loading...",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 200, // Szerokość paska ładowania
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blue),
                    minHeight: 8, // Wysokość paska
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "${(_progress * 100).toInt()}%",
                  style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

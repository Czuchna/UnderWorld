import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:underworld_game/router.dart';
import 'package:underworld_game/widgets/menu_button.dart';
import 'package:underworld_game/widgets/top_panel.dart';

@RoutePage()
class MainMenuScreen extends StatelessWidget {
  final String userId = "12345"; // ID użytkownika
  final int userLevel = 10; // Poziom użytkownika
  final int redCrystals = 17518;
  final int blueCrystals = 3184;

  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: statusBarHeight,
            left: 0,
            right: 0,
            child: TopPanelWidget(
              userId: userId,
              userLevel: userLevel,
              redCrystals: redCrystals,
              blueCrystals: blueCrystals,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.withOpacity(0.8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                onPressed: () {
                  context.router.push(const GameRoute());
                },
                child: const Text("Enter"),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: Colors.black.withOpacity(0.4),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MenuButtonWidget(label: "Ekwipunek", icon: Icons.backpack),
                  MenuButtonWidget(label: "Rozwój", icon: Icons.upgrade),
                  MenuButtonWidget(label: "Baza", icon: Icons.home),
                  MenuButtonWidget(label: "Obóz", icon: Icons.campaign_rounded),
                  MenuButtonWidget(label: "Sklep", icon: Icons.shop),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

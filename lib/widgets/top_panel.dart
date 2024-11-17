import 'package:flutter/material.dart';
import 'package:underworld_game/widgets/crystal.dart';

class TopPanelWidget extends StatelessWidget {
  final String userId;
  final int userLevel;
  final int redCrystals;
  final int blueCrystals;

  const TopPanelWidget({
    required this.userId,
    required this.userLevel,
    required this.redCrystals,
    required this.blueCrystals,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.black.withOpacity(0.7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6.0),
                child: Text(
                  "Lv. $userLevel",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "ID: $userId",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  CrystalWidget(
                    assetPath: "assets/images/red_crystal.png",
                    count: redCrystals,
                  ),
                  const SizedBox(width: 10),
                  CrystalWidget(
                    assetPath: "assets/images/blue_crystal.png",
                    count: blueCrystals,
                  ),
                ],
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            onSelected: (value) {},
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(value: "account", child: Text("Konto")),
                const PopupMenuItem(
                    value: "notifications", child: Text("Powiadomienia")),
                const PopupMenuItem(
                    value: "mailbox", child: Text("Skrzynka pocztowa")),
                const PopupMenuItem(value: "ranking", child: Text("Ranking")),
                const PopupMenuItem(
                    value: "logs", child: Text("Historia logów")),
                const PopupMenuItem(value: "settings", child: Text("Opcje")),
                const PopupMenuItem(
                    value: "exit", child: Text("Wyjście z gry")),
              ];
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class CrystalWidget extends StatelessWidget {
  final String assetPath;
  final int count;

  const CrystalWidget({
    required this.assetPath,
    required this.count,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          assetPath,
          width: 30,
          height: 30,
        ),
        const SizedBox(width: 5),
        Text(
          "$count",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

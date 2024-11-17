import 'package:flutter/material.dart';
import 'package:underworld_game/router.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final AppRouter _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Underworld Game',
      routerConfig: _appRouter.config(),
    );
  }
}

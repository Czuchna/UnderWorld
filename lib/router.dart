import 'package:auto_route/auto_route.dart';
import 'package:underworld_game/screens/loading_screen.dart';
import 'package:underworld_game/screens/main_menu.dart';
import 'package:underworld_game/screens/game_screen.dart';

part 'router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: LoadingRoute.page, initial: true),
        AutoRoute(page: MainMenuRoute.page),
        AutoRoute(page: GameRoute.page),
      ];
}

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:spt/models/plots_model.dart';
import 'package:spt/models/route_model.dart';
import 'package:spt/screens/MainPage.dart';
import '../screens/splash_screen.dart';
import '../screens/WelcomePage.dart';
import '../screens/login.dart';
import '../screens/registor_page.dart';
import '../screens/ProfilePage.dart';
import '../screens/SearchPage.dart';
import '../screens/rewirdPage.dart';
import '../screens/detailPlacePage.dart';
import '../screens/AddPlacePage.dart';
import '../screens/mapPage.dart';
import '../screens/AdminPage.dart';
import '../screens/routesPage.dart';
import '../screens/detailRoutePage.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page|Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, initial: true),
    AutoRoute(page: WelcomeRoute.page),
    AutoRoute(page: LoginRoute.page),
    AutoRoute(page: RegistorRoute.page),
    AutoRoute(
      page: MainRoute.page,
      children: [
        AutoRoute(page: MapRoute.page),
        AutoRoute(page: ProfileRoute.page),
        AutoRoute(page: SearchRoute.page),
        AutoRoute(page: RewidRoute.page),
        AutoRoute(page: AddPlaceRoute.page),
        AutoRoute(page: RoutesRoute.page),
      ],
    ),
    AutoRoute(page: DetailPlaceRoute.page),
    AutoRoute(page: AdminRoute.page),
    AutoRoute(page: DetailRouteRoute.page),
  ];
}

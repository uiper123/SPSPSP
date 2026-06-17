// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [AddPlacePage]
class AddPlaceRoute extends PageRouteInfo<void> {
  const AddPlaceRoute({List<PageRouteInfo>? children})
    : super(AddPlaceRoute.name, initialChildren: children);

  static const String name = 'AddPlaceRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AddPlacePage();
    },
  );
}

/// generated route for
/// [AdminPage]
class AdminRoute extends PageRouteInfo<void> {
  const AdminRoute({List<PageRouteInfo>? children})
    : super(AdminRoute.name, initialChildren: children);

  static const String name = 'AdminRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminPage();
    },
  );
}

/// generated route for
/// [DetailPlacePage]
class DetailPlaceRoute extends PageRouteInfo<DetailPlaceRouteArgs> {
  DetailPlaceRoute({
    Key? key,
    required PlotsModel plot,
    List<PageRouteInfo>? children,
  }) : super(
         DetailPlaceRoute.name,
         args: DetailPlaceRouteArgs(key: key, plot: plot),
         initialChildren: children,
       );

  static const String name = 'DetailPlaceRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DetailPlaceRouteArgs>();
      return DetailPlacePage(key: args.key, plot: args.plot);
    },
  );
}

class DetailPlaceRouteArgs {
  const DetailPlaceRouteArgs({this.key, required this.plot});

  final Key? key;

  final PlotsModel plot;

  @override
  String toString() {
    return 'DetailPlaceRouteArgs{key: $key, plot: $plot}';
  }
}

/// generated route for
/// [DetailRoutePage]
class DetailRouteRoute extends PageRouteInfo<DetailRouteRouteArgs> {
  DetailRouteRoute({
    Key? key,
    required RouteModel route,
    List<PageRouteInfo>? children,
  }) : super(
         DetailRouteRoute.name,
         args: DetailRouteRouteArgs(key: key, route: route),
         initialChildren: children,
       );

  static const String name = 'DetailRouteRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DetailRouteRouteArgs>();
      return DetailRoutePage(key: args.key, route: args.route);
    },
  );
}

class DetailRouteRouteArgs {
  const DetailRouteRouteArgs({this.key, required this.route});

  final Key? key;

  final RouteModel route;

  @override
  String toString() {
    return 'DetailRouteRouteArgs{key: $key, route: $route}';
  }
}

/// generated route for
/// [LoginPage]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LoginPage();
    },
  );
}

/// generated route for
/// [MainPage]
class MainRoute extends PageRouteInfo<void> {
  const MainRoute({List<PageRouteInfo>? children})
    : super(MainRoute.name, initialChildren: children);

  static const String name = 'MainRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MainPage();
    },
  );
}

/// generated route for
/// [MapPage]
class MapRoute extends PageRouteInfo<MapRouteArgs> {
  MapRoute({
    Key? key,
    String? focusCoordinates,
    String? focusName,
    List<PageRouteInfo>? children,
  }) : super(
         MapRoute.name,
         args: MapRouteArgs(
           key: key,
           focusCoordinates: focusCoordinates,
           focusName: focusName,
         ),
         initialChildren: children,
       );

  static const String name = 'MapRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MapRouteArgs>(
        orElse: () => const MapRouteArgs(),
      );
      return MapPage(
        key: args.key,
        focusCoordinates: args.focusCoordinates,
        focusName: args.focusName,
      );
    },
  );
}

class MapRouteArgs {
  const MapRouteArgs({this.key, this.focusCoordinates, this.focusName});

  final Key? key;

  final String? focusCoordinates;

  final String? focusName;

  @override
  String toString() {
    return 'MapRouteArgs{key: $key, focusCoordinates: $focusCoordinates, focusName: $focusName}';
  }
}

/// generated route for
/// [ProfilePage]
class ProfileRoute extends PageRouteInfo<void> {
  const ProfileRoute({List<PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProfilePage();
    },
  );
}

/// generated route for
/// [RegistorPage]
class RegistorRoute extends PageRouteInfo<void> {
  const RegistorRoute({List<PageRouteInfo>? children})
    : super(RegistorRoute.name, initialChildren: children);

  static const String name = 'RegistorRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const RegistorPage();
    },
  );
}

/// generated route for
/// [RewidPage]
class RewidRoute extends PageRouteInfo<void> {
  const RewidRoute({List<PageRouteInfo>? children})
    : super(RewidRoute.name, initialChildren: children);

  static const String name = 'RewidRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const RewidPage();
    },
  );
}

/// generated route for
/// [RoutesPage]
class RoutesRoute extends PageRouteInfo<void> {
  const RoutesRoute({List<PageRouteInfo>? children})
    : super(RoutesRoute.name, initialChildren: children);

  static const String name = 'RoutesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const RoutesPage();
    },
  );
}

/// generated route for
/// [SearchPage]
class SearchRoute extends PageRouteInfo<void> {
  const SearchRoute({List<PageRouteInfo>? children})
    : super(SearchRoute.name, initialChildren: children);

  static const String name = 'SearchRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SearchPage();
    },
  );
}

/// generated route for
/// [SplashScreen]
class SplashRoute extends PageRouteInfo<void> {
  const SplashRoute({List<PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return SplashScreen();
    },
  );
}

/// generated route for
/// [WelcomePage]
class WelcomeRoute extends PageRouteInfo<void> {
  const WelcomeRoute({List<PageRouteInfo>? children})
    : super(WelcomeRoute.name, initialChildren: children);

  static const String name = 'WelcomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const WelcomePage();
    },
  );
}

class MapFocusState {
  static final MapFocusState _instance = MapFocusState._internal();
  factory MapFocusState() => _instance;
  MapFocusState._internal();

  String? pendingCoordinates;
  String? pendingName;
  int? pendingRouteId;
  List<String>? pendingRouteCoordinates;
  String? pendingRouteName;

  void setFocus(String coordinates, String name) {
    pendingCoordinates = coordinates;
    pendingName = name;
  }

  void setRouteFocus(int routeId, List<String> coordinates, String name) {
    pendingRouteId = routeId;
    pendingRouteCoordinates = coordinates;
    pendingRouteName = name;
  }

  void clearPointFocus() {
    pendingCoordinates = null;
    pendingName = null;
  }

  void clearRouteFocus() {
    pendingRouteId = null;
    pendingRouteCoordinates = null;
    pendingRouteName = null;
  }

  void clear() {
    clearPointFocus();
    clearRouteFocus();
  }
}

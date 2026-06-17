import 'dart:async';

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:spt/routing/app_router.dart';
import 'package:spt/core/constant/colors.dart';
import 'package:spt/models/plots_model.dart';
import 'package:spt/serv/searchPlots_serv.dart';
import 'package:spt/core/map_focus.dart';
import 'package:spt/core/constant/api_constants.dart';
import 'package:spt/serv/route_serv.dart';
import 'package:spt/core/utils/snackbar_helper.dart';

@RoutePage()
class MapPage extends StatefulWidget {
  final String? focusCoordinates;
  final String? focusName;
  const MapPage({super.key, this.focusCoordinates, this.focusName});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final MapController _mapController;
  Position? _currentPosition;
  Marker? _userMarker;
  StreamSubscription<Position>? _positionStreamSubscription;
  final double _maxZoom = 17;
  final double _minZoom = 3;

  List<PlotsModel> _places = [];
  int? _trackedRouteId;
  List<LatLng> _trackedRoutePoints = [];
  List<LatLng> _trackedRoutePolylinePoints = [];
  String? _trackedRouteName;
  bool _isRouteTrackingActive = false;
  bool _isRoutePathLoading = false;
  bool _shouldFitTrackedRouteWithUser = false;
  final SearchPlots _searchService = SearchPlots();
  final RouteService _routeService = RouteService();

  TabsRouter? _tabsRouter;

  @override
  void initState() {
    _mapController = MapController();
    super.initState();
    _loadPlaces();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final tabsRouter = AutoTabsRouter.of(context, watch: true);
      if (_tabsRouter != tabsRouter) {
        if (_tabsRouter != null) {
          _tabsRouter!.removeListener(_onTabChange);
        }
        _tabsRouter = tabsRouter;
        _tabsRouter!.addListener(_onTabChange);
      }
    } catch (_) {}
  }

  void _onTabChange() {
    if (_tabsRouter?.activeIndex == 0) {
      if (mounted) {
        _loadPlaces();
        _checkFocusState();
      }
    }
  }

  void _checkFocusState() {
    final focusState = MapFocusState();
    final pendingRoute = focusState.pendingRouteCoordinates;
    if (pendingRoute != null && pendingRoute.isNotEmpty) {
      final routePoints = pendingRoute
          .map(_parseCoords)
          .whereType<LatLng>()
          .toList();
      if (routePoints.isNotEmpty) {
        _activateTrackedRoute(
          routeId: focusState.pendingRouteId,
          routePoints: routePoints,
          routeName: focusState.pendingRouteName,
        );
      }
      focusState.clearRouteFocus();
    }

    if (focusState.pendingCoordinates == null) return;

    final coords = _parseCoords(focusState.pendingCoordinates!);
    if (coords != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _mapController.move(coords, 16);
          focusState.clearPointFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _tabsRouter?.removeListener(_onTabChange);
    _positionStreamSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    final places = await _searchService.searchPlots();
    setState(() {
      _places = places;
    });

    _checkFocusState();

    if (widget.focusCoordinates != null &&
        widget.focusCoordinates!.isNotEmpty) {
      final coords = _parseCoords(widget.focusCoordinates!);
      if (coords != null) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            _mapController.move(coords, 16);
          }
        });
      }
    }
  }

  LatLng? _parseCoords(String coordStr) {
    if (coordStr.isEmpty) return null;
    try {
      final parts = coordStr.split(',');
      if (parts.length == 2) {
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        return LatLng(lat, lng);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  List<Marker> _buildPlaceMarkers() {
    final markers = <Marker>[];
    for (final place in _places) {
      final latLng = _parseCoords(place.coordinates);
      if (latLng == null) continue;
      markers.add(
        Marker(
          point: latLng,
          width: 50,
          height: 50,
          alignment: Alignment.center,
          child: InkWell(
            onTap: () => _showMarkerInfo(place),
            child: Icon(
              Icons.location_on,
              color: const Color.fromARGB(255, 120, 31, 155),
              size: 30,
            ),
          ),
        ),
      );
    }
    return markers;
  }

  List<Marker> _buildTrackedRouteMarkers() {
    return _trackedRoutePoints.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      final isFirst = index == 0;
      final isLast = index == _trackedRoutePoints.length - 1;

      return Marker(
        point: point,
        width: 42,
        height: 42,
        alignment: Alignment.center,
        child: _TrackedRoutePointMarker(
          index: index,
          isFirst: isFirst,
          isLast: isLast,
        ),
      );
    }).toList();
  }

  void _activateTrackedRoute({
    required int? routeId,
    required List<LatLng> routePoints,
    required String? routeName,
  }) {
    if (routePoints.isEmpty) return;
    setState(() {
      _trackedRouteId = routeId;
      _trackedRoutePoints = routePoints;
      _trackedRoutePolylinePoints = routePoints;
      _trackedRouteName = routeName;
      _isRouteTrackingActive = true;
      _isRoutePathLoading = routeId != null;
      _shouldFitTrackedRouteWithUser = true;
    });

    _loadTrackedRoutePath();
    _startRouteTracking();
    _fitTrackedRoute(delayMs: 350);
  }

  Future<void> _loadTrackedRoutePath() async {
    final routeId = _trackedRouteId;
    if (routeId == null) {
      if (mounted) {
        setState(() => _isRoutePathLoading = false);
      }
      return;
    }

    final routePath = await _routeService.getRoutePath(routeId);
    if (!mounted || _trackedRouteId != routeId) return;

    if (routePath == null || routePath.points.length < 2) {
      setState(() => _isRoutePathLoading = false);
      return;
    }

    setState(() {
      _trackedRoutePolylinePoints = routePath.points
          .map((point) => LatLng(point.lat, point.lng))
          .toList();
      _isRoutePathLoading = false;
    });
    _fitTrackedRoute();
  }

  void _stopTrackedRoute() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    if (!mounted) return;
    setState(() {
      _trackedRouteId = null;
      _trackedRoutePoints = [];
      _trackedRoutePolylinePoints = [];
      _trackedRouteName = null;
      _isRouteTrackingActive = false;
      _isRoutePathLoading = false;
      _shouldFitTrackedRouteWithUser = false;
    });
  }

  Future<bool> _ensureLocationAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMapSnackBar('Включите геолокацию, чтобы отслеживать маршрут');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showMapSnackBar('Разрешите доступ к геолокации');
      return false;
    }

    return true;
  }

  Future<void> _startRouteTracking() async {
    if (!await _ensureLocationAccess()) return;

    try {
      await _positionStreamSubscription?.cancel();

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );

      final currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      _updateUserMarker(currentPosition);

      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (position) {
              _updateUserMarker(position);
              if (_isRouteTrackingActive && _shouldFitTrackedRouteWithUser) {
                _shouldFitTrackedRouteWithUser = false;
                _fitTrackedRoute();
              }
            },
            onError: (_) {
              _showMapSnackBar('Не удалось обновить геолокацию');
            },
          );
    } catch (_) {
      _showMapSnackBar('Не удалось определить текущее местоположение');
    }
  }

  void _updateUserMarker(Position position) {
    if (!mounted) return;
    final point = LatLng(position.latitude, position.longitude);
    setState(() {
      _currentPosition = position;
      _userMarker = Marker(
        point: point,
        width: 54,
        height: 54,
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: const Icon(
            Icons.my_location,
            color: Color.fromARGB(255, 43, 179, 156),
            size: 28,
          ),
        ),
      );
    });
  }

  void _fitTrackedRoute({int delayMs = 0}) {
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted || _trackedRoutePolylinePoints.isEmpty) return;

      final focusPoints = <LatLng>[
        ..._trackedRoutePolylinePoints,
        if (_currentPosition != null)
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      ];

      if (focusPoints.length == 1) {
        _mapController.move(focusPoints.first, 15);
        return;
      }

      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: focusPoints,
          padding: const EdgeInsets.only(
            left: 40,
            right: 40,
            top: 110,
            bottom: 220,
          ),
          maxZoom: 16,
        ),
      );
    });
  }

  void _showMapSnackBar(String message) {
    if (!mounted) return;
    showFloatingSnackBar(
      context,
      message,
    );
  }

  void _showMarkerInfo(PlotsModel place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: place.image.isNotEmpty
                    ? Image.network(
                        '${ApiConstants.baseUrl}${place.image}',
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (place.averageRating > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber[200]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  place.averageRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        if (place.type.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              place.type,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (place.location.isNotEmpty)
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    place.location,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    if (place.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        place.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    if (place.authorName.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.accentColor.withOpacity(
                              0.15,
                            ),
                            child: Text(
                              place.authorName.isNotEmpty
                                  ? place.authorName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            place.authorName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await context.router.push(
                            DetailPlaceRoute(plot: place),
                          );
                          _loadPlaces();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Подробнее',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 180,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(
            'Нет фото',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _getPosUser() async {
    if (!await _ensureLocationAccess()) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );
      _updateUserMarker(position);
      _mapController.move(LatLng(position.latitude, position.longitude), 15);
    } catch (_) {
      _showMapSnackBar('Не удалось определить текущее местоположение');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(55.755793, 37.617134),
          initialZoom: 5,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.flutter_map_example',
          ),
          if (_trackedRoutePolylinePoints.length >= 2)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _trackedRoutePolylinePoints,
                  strokeWidth: 5,
                  color: AppColors.accentColor,
                  borderColor: Colors.white,
                  borderStrokeWidth: 2,
                ),
              ],
            ),
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 45,
              size: const Size(40, 40),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(10),
              markers: [
                ..._buildPlaceMarkers(),
                if (_userMarker != null) _userMarker!,
              ],
              builder: (context, markers) {
                return _ClusterMarker(markersLength: markers.length.toString());
              },
            ),
          ),
          if (_trackedRoutePoints.isNotEmpty)
            MarkerLayer(markers: _buildTrackedRouteMarkers()),
          Stack(
            children: [
              if (_isRouteTrackingActive)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.route_rounded,
                            color: AppColors.accentColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _trackedRouteName?.isNotEmpty == true
                                    ? _trackedRouteName!
                                    : 'Пользовательский маршрут',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isRoutePathLoading
                                    ? 'Строим маршрут по дорогам...'
                                    : 'Отслеживание включено • ${_trackedRoutePoints.length} точек',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _fitTrackedRoute,
                          icon: const Icon(Icons.fit_screen_outlined),
                          tooltip: 'Показать весь маршрут',
                        ),
                        IconButton(
                          onPressed: _stopTrackedRoute,
                          icon: const Icon(Icons.close),
                          tooltip: 'Остановить',
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                bottom: 130,
                right: 20,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 10,
                  children: [
                    FloatingActionButton(
                      heroTag: 'zoom_in',
                      onPressed: () {
                        if (_mapController.camera.zoom < _maxZoom) {
                          _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom + 1,
                          );
                        }
                      },
                      child: Icon(Icons.add),
                    ),
                    FloatingActionButton(
                      heroTag: 'zoom_out',
                      onPressed: () {
                        if (_mapController.camera.zoom > _minZoom) {
                          _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom - 1,
                          );
                        }
                      },
                      child: Icon(Icons.remove),
                    ),
                    FloatingActionButton(
                      heroTag: 'my_location',
                      onPressed: () {
                        if (_currentPosition != null) {
                          _mapController.move(
                            LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            15,
                          );
                        } else {
                          _getPosUser();
                        }
                      },
                      child: Icon(Icons.location_on),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 85,
                right: 20,
                child: Text(
                  '@ OpenStreetMap contributors',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackedRoutePointMarker extends StatelessWidget {
  const _TrackedRoutePointMarker({
    required this.index,
    required this.isFirst,
    required this.isLast,
  });

  final int index;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    if (isFirst) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF00B48F),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.flag_rounded, color: Colors.white, size: 18),
        ),
      );
    }

    if (isLast) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE53935),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accentColor,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ClusterMarker extends StatelessWidget {
  const _ClusterMarker({required this.markersLength});
  final String markersLength;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.colorlight.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.colorlight, width: 3),
      ),
      child: Center(
        child: Text(
          markersLength,
          style: TextStyle(
            color: AppColors.colordark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

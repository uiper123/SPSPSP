import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:spt/core/auth/token_storage.dart';
import 'package:spt/core/constant/colors.dart';
import 'package:spt/core/constant/api_constants.dart';
import 'package:spt/models/route_model.dart';
import 'package:spt/serv/route_serv.dart';
import 'package:spt/routing/app_router.dart';
import 'package:spt/widgets/route_editor_sheet.dart';

@RoutePage()
class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  List<RouteModel> _routes = [];
  List<RouteModel> _filteredRoutes = [];
  bool _isLoading = true;
  bool _isLoggedIn = false;
  final RouteService _routeService = RouteService();
  final TextEditingController _searchController = TextEditingController();
  int _displayedRouteCount = 10;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    _checkAuth();
    _searchController.addListener(_filterRoutes);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterRoutes);
    _searchController.dispose();
    super.dispose();
  }

  void _filterRoutes() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredRoutes = List.from(_routes);
      } else {
        _filteredRoutes = _routes.where((r) {
          return r.name.toLowerCase().contains(query) ||
              (r.description?.toLowerCase().contains(query) ?? false) ||
              r.authorName.toLowerCase().contains(query);
        }).toList();
      }
      _displayedRouteCount = 10;
    });
  }

  Future<void> _checkAuth() async {
    final token = await tokenStorage.readToken();
    if (mounted) {
      setState(() => _isLoggedIn = token != null);
    }
  }

  Future<void> _loadRoutes() async {
    final routes = await _routeService.getRoutes();
    if (mounted) {
      setState(() {
        _routes = routes;
        _filteredRoutes = routes;
        _isLoading = false;
        _displayedRouteCount = 10;
      });
    }
  }

  void _showCreateRouteModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => RouteEditorSheet(
        onSaved: (_) {
          _loadRoutes();
        },
      ),
    );
  }

  Widget _buildRouteCard(RouteModel route) {
    final previewPlaces = route.places.length > 4
        ? <RoutePlaceItem>[...route.places.take(3), route.places.last]
        : route.places;
    final hiddenPlacesCount = route.places.length > 4
        ? route.places.length - 4
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            await context.router.push(DetailRouteRoute(route: route));
            if (mounted) _loadRoutes();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.route_rounded,
                        color: AppColors.accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 13,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                route.authorName.isNotEmpty
                                    ? route.authorName
                                    : 'Пользователь',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              route.averageRating > 0
                                  ? route.averageRating.toStringAsFixed(1)
                                  : '—',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${route.places.length} мест',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (previewPlaces.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < previewPlaces.length; i++) ...[
                          if (hiddenPlacesCount > 0 &&
                              i == previewPlaces.length - 1) ...[
                            _buildHiddenRoutePlaces(hiddenPlacesCount),
                            _buildRouteConnector(),
                          ],
                          _buildRoutePoint(
                            icon: i == 0
                                ? Icons.flag_rounded
                                : i == previewPlaces.length - 1 &&
                                      route.places.length > 1
                                ? Icons.location_on_rounded
                                : Icons.fiber_manual_record,
                            iconColor: i == 0
                                ? const Color(0xFF00B48F)
                                : i == previewPlaces.length - 1 &&
                                      route.places.length > 1
                                ? const Color(0xFFE53935)
                                : const Color(0xFF5E35B1),
                            label: i == 0
                                ? 'Начало'
                                : i == previewPlaces.length - 1 &&
                                      route.places.length > 1
                                ? 'Конец'
                                : 'Точка ${i + 1}',
                            name: previewPlaces[i].name,
                            image: previewPlaces[i].image,
                          ),
                          if (i != previewPlaces.length - 1)
                            _buildRouteConnector(),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 9),
      child: Row(
        children: [Container(width: 2, height: 16, color: Colors.grey[300])],
      ),
    );
  }

  Widget _buildHiddenRoutePlaces(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.more_horiz, color: Colors.grey[400], size: 18),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.more_horiz, size: 18, color: Colors.grey[500]),
          ),
          const SizedBox(width: 10),
          Text(
            _hiddenPlacesText(count),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _hiddenPlacesText(int count) {
    final lastTwoDigits = count % 100;
    final lastDigit = count % 10;
    if (lastTwoDigits >= 11 && lastTwoDigits <= 14) {
      return 'Ещё $count мест';
    }
    if (lastDigit == 1) {
      return 'Ещё $count место';
    }
    if (lastDigit >= 2 && lastDigit <= 4) {
      return 'Ещё $count места';
    }
    return 'Ещё $count мест';
  }

  Widget _buildRoutePoint({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String name,
    required String image,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        if (image.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              '${ApiConstants.baseUrl}$image',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 32,
                height: 32,
                color: Colors.grey[200],
                child: Icon(Icons.image, size: 16, color: Colors.grey[400]),
              ),
            ),
          )
        else
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.image, size: 16, color: Colors.grey[400]),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.mainGradient),
            height: MediaQuery.of(context).size.height * 0.22,
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      const Text(
                        'Маршруты',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.route_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Поиск маршрутов...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[400]),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredRoutes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.route_rounded,
                                  size: 60,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _routes.isEmpty
                                      ? 'Пока нет маршрутов'
                                      : 'Ничего не найдено',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_routes.isEmpty)
                                  Text(
                                    'Будьте первым — создайте свой маршрут!',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadRoutes,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                10,
                                16,
                                100,
                              ),
                              itemCount:
                                  _filteredRoutes.length > _displayedRouteCount
                                  ? _displayedRouteCount + 1
                                  : _filteredRoutes.length,
                              itemBuilder: (context, index) {
                                if (index == _displayedRouteCount) {
                                  return _buildShowMoreRoutesButton();
                                }
                                return _buildRouteCard(_filteredRoutes[index]);
                              },
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoggedIn)
            Positioned(
              bottom: 90,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: _showCreateRouteModal,
                backgroundColor: AppColors.accentColor,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Создать маршрут',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShowMoreRoutesButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _displayedRouteCount += 10;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
        child: const Text(
          'Показать еще',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

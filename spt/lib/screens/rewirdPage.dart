import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:spt/routing/app_router.dart';
import 'package:spt/models/plots_model.dart';
import 'package:spt/models/route_model.dart';
import 'package:spt/serv/favorites_serv.dart';
import 'package:spt/serv/route_serv.dart';
import 'package:spt/widgets/address_text.dart';

import 'package:spt/core/constant/colors.dart';
import 'package:spt/core/constant/api_constants.dart';

@RoutePage()
class RewidPage extends StatefulWidget {
  const RewidPage({super.key});
  @override
  State<RewidPage> createState() => _RewidPageState();
}

class _RewidPageState extends State<RewidPage>
    with SingleTickerProviderStateMixin {
  List<PlotsModel> _favorites = [];
  List<RouteModel> _favoriteRoutes = [];
  bool _isLoading = true;
  bool _isRoutesLoading = true;
  final FavoritesService _favoritesService = FavoritesService();
  final RouteService _routeService = RouteService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
    _loadFavoriteRoutes();
  }

  TabsRouter? _tabsRouter;

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
    if (_tabsRouter?.activeIndex == 3) {
      if (mounted) {
        _loadFavorites();
        _loadFavoriteRoutes();
      }
    }
  }

  @override
  void dispose() {
    _tabsRouter?.removeListener(_onTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _favoritesService.getMyFavorites();
    if (mounted) {
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFavoriteRoutes() async {
    final routes = await _routeService.getMyFavoriteRoutes();
    if (mounted) {
      setState(() {
        _favoriteRoutes = routes;
        _isRoutesLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(PlotsModel plot) async {
    final result = await _favoritesService.toggleFavorite(plot.id);
    if (!result) {
      setState(() {
        _favorites.removeWhere((p) => p.id == plot.id);
      });
    }
  }

  Widget _buildFavoriteCard(PlotsModel plot) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await context.router.push(DetailPlaceRoute(plot: plot));
          _loadFavorites();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: plot.image.isNotEmpty
                      ? Image.network(
                          '${ApiConstants.baseUrl}${plot.image}',
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: double.infinity,
                                height: 180,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey[400],
                                  size: 50,
                                ),
                              ),
                        )
                      : Container(
                          width: double.infinity,
                          height: 180,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image,
                            color: Colors.grey[400],
                            size: 50,
                          ),
                        ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _removeFavorite(plot),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(Icons.favorite, color: Colors.red, size: 20),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        SizedBox(width: 4),
                        Text(
                          plot.averageRating > 0
                              ? plot.averageRating.toString()
                              : '0.0',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          plot.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          plot.type,
                          style: TextStyle(
                            color: AppColors.accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: AddressText(
                          initialLocation: plot.location,
                          coordinates: plot.coordinates,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.mainGradient),
            height: MediaQuery.of(context).size.height * 0.2,
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      const Text(
                        'Избранное',
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
                        child: const Icon(Icons.favorite, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppColors.accentColor,
                    unselectedLabelColor: Colors.white,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Места'),
                      Tab(text: 'Маршруты'),
                    ],
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
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildPlacesTab(), _buildRoutesTab()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacesTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _favorites.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Нет избранных мест',
                  style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadFavorites,
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: 20,
                left: 15,
                right: 15,
                bottom: 80,
              ),
              itemCount: _favorites.length,
              itemBuilder: (context, index) =>
                  _buildFavoriteCard(_favorites[index]),
            ),
          );
  }

  Widget _buildRoutesTab() {
    return _isRoutesLoading
        ? const Center(child: CircularProgressIndicator())
        : _favoriteRoutes.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.route_rounded, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Нет избранных маршрутов',
                  style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadFavoriteRoutes,
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: 20,
                left: 15,
                right: 15,
                bottom: 80,
              ),
              itemCount: _favoriteRoutes.length,
              itemBuilder: (context, index) =>
                  _buildFavoriteRouteCard(_favoriteRoutes[index]),
            ),
          );
  }

  Widget _buildFavoriteRouteCard(RouteModel route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await context.router.push(DetailRouteRoute(route: route));
          if (mounted) _loadFavoriteRoutes();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${route.places.length} мест · ${route.authorName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
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
            ],
          ),
        ),
      ),
    );
  }
}

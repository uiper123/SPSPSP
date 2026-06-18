import 'dart:io';

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spt/core/constant/colors.dart';
import 'package:spt/core/utils/snackbar_helper.dart';
import 'package:spt/core/constant/api_constants.dart';
import 'package:spt/models/user_model.dart';
import 'package:spt/models/plots_model.dart';
import 'package:spt/models/route_model.dart';
import 'package:spt/routing/app_router.dart';
import 'package:spt/serv/profile_serv.dart';
import 'package:spt/serv/auth_serv.dart';
import 'package:spt/serv/myPlaces_serv.dart';
import 'package:spt/serv/route_serv.dart';
import 'package:spt/serv/admin_serv.dart';
import 'package:spt/serv/category_serv.dart';
import 'package:spt/widgets/address_text.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

@RoutePage()
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isPasswordVisible = false;
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _patronymicController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordController2 = TextEditingController();
  UserModel? _currentUser;
  final _formKey = GlobalKey<FormState>();

  XFile? _image;
  final ProfileService _profileService = ProfileService();
  final MyPlacesService _myPlacesService = MyPlacesService();
  final RouteService _routeService = RouteService();
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  bool _isGuest = false;

  List<PlotsModel> _myPlaces = [];
  bool _myPlacesLoading = true;
  List<RouteModel> _myRoutes = [];
  bool _myRoutesLoading = true;
  int _favoritesCount = 0;
  int _displayedMyPlacesCount = 10;
  int _displayedMyRoutesCount = 10;

  int _pendingCount = 0;
  int _reportsCount = 0;
  int _approvedCount = 0;
  int _declinedCount = 0;
  int _usersCount = 0;
  int _allPlacesCount = 0;
  List<PlotsModel> _pendingPlaces = [];
  List<PlotsModel> _approvedPlaces = [];
  List<PlotsModel> _declinedPlaces = [];
  List<ReportPlacesModel> _reports = [];
  List<UserModel> _users = [];
  List<PlotsModel> _allPlaces = [];
  List<RouteModel> _allRoutes = [];

  int _categoriesCount = 0;
  List<CategoryModel> _categories = [];
  final CategoryService _categoryService = CategoryService();

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadMyPlaces();
    _loadMyRoutes();
    _loadFavoritesCount();
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
    if (_tabsRouter?.activeIndex == 4) {
      if (mounted) {
        _loadUser();
        _loadMyPlaces();
        _loadMyRoutes();
        _loadFavoritesCount();
        _loadAdminData();
      }
    }
  }

  Future<void> _loadAdminData() async {
    final role = _currentUser?.id_role ?? 1;
    if (role != 2 && role != 3) return;

    final pending = await _adminService.getPlacesByStatus(1);
    final approved = await _adminService.getPlacesByStatus(2);
    final declined = await _adminService.getPlacesByStatus(3);
    final reports = await _adminService.getReports();
    final routes = await _adminService.getAllRoutes();

    if (mounted) {
      setState(() {
        _pendingPlaces = pending;
        _pendingCount = pending.length;
        _approvedPlaces = approved;
        _approvedCount = approved.length;
        _declinedPlaces = declined;
        _declinedCount = declined.length;
        _reports = reports;
        _reportsCount = reports.length;
        _allPlaces = [...pending, ...approved, ...declined];
        _allPlacesCount = _allPlaces.length;
        _allRoutes = routes;
      });
    }

    final users = await _adminService.getUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _usersCount = users.length;
      });
    }

    final categories = await _categoryService.getCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        _categoriesCount = categories.length;
      });
    }
  }

  @override
  void dispose() {
    _tabsRouter?.removeListener(_onTabChange);
    _nameController.dispose();
    _surnameController.dispose();
    _patronymicController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordController2.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await _profileService.getuserMe();
    if (user != null) {
      setState(() {
        _nameController.text = user.first_name;
        _surnameController.text = user.last_name;
        _patronymicController.text = user.patronymic ?? '';
        _emailController.text = user.email;
        _isLoading = false;
        _currentUser = user;
      });
      _loadAdminData();
    } else {
      setState(() {
        _isLoading = false;
        _isGuest = true;
      });
    }
  }

  Future<void> _loadMyPlaces() async {
    final places = await _myPlacesService.getMyPlaces();
    if (!mounted) return;
    setState(() {
      _myPlaces = places;
      _myPlacesLoading = false;
      _displayedMyPlacesCount = 10;
    });
  }

  Future<void> _loadMyRoutes() async {
    final routes = await _routeService.getMyRoutes();
    if (!mounted) return;
    setState(() {
      _myRoutes = routes;
      _myRoutesLoading = false;
      _displayedMyRoutesCount = 10;
    });
  }

  Future<void> _loadFavoritesCount() async {
    final count = await _myPlacesService.getFavoritesCount();
    if (!mounted) return;
    setState(() {
      _favoritesCount = count;
    });
  }

  Future<void> _refreshProfileData() async {
    await _loadUser();
    await _loadMyPlaces();
    await _loadMyRoutes();
    await _loadFavoritesCount();
    await _loadAdminData();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Выход из аккаунта'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Выйти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService().deleteToken();
      if (mounted) context.router.root.push(const LoginRoute());
    }
  }

  Future<void> _pickImage(setModalState) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = image;
      });

      setModalState(() {});
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onVisibilityToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        labelStyle: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('одобр') || s.contains('актив') || s.contains('подтвер')) {
      return Colors.green;
    }
    if (s.contains('отклон') || s.contains('отказ')) {
      return Colors.red;
    }
    return Colors.orange;
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return 'На модерации';
    return status;
  }

  Widget _buildMyPlaceCard(PlotsModel place) {
    final statusColor = _statusColor(place.status);
    final statusLabel = _statusLabel(place.status);

    return GestureDetector(
      onTap: () async {
        await context.router.push(DetailPlaceRoute(plot: place));
        _loadMyPlaces();
        _loadFavoritesCount();
      },
      child: Container(
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    place.image.isNotEmpty
                        ? Image.network(
                            '${ApiConstants.baseUrl}${place.image}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.image_outlined,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[100],
                            child: Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: Colors.grey[300],
                            ),
                          ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (place.type.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 11,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                place.type,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 11,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: AddressText(
                              initialLocation: place.location,
                              coordinates: place.coordinates,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyRouteCard(RouteModel route) {
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
          if (mounted) _loadMyRoutes();
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
                      '${route.places.length} мест',
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

  Widget _buildProfileEmptyBlock({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMainTab() {
    return RefreshIndicator(
      onRefresh: _refreshProfileData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Созданные места',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_myPlaces.length}',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_myPlacesLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_myPlaces.isEmpty)
            _buildProfileEmptyBlock(
              icon: Icons.add_location_alt_outlined,
              title: 'У вас ещё нет мест',
              subtitle: 'Добавьте первое место, нажав на кнопку + на главной',
            )
          else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _myPlaces.length > _displayedMyPlacesCount
                  ? _displayedMyPlacesCount
                  : _myPlaces.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.78,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final place = _myPlaces[index];
                return _buildMyPlaceCard(place);
              },
            ),
            if (_myPlaces.length > _displayedMyPlacesCount)
              _buildProfileShowMoreButton(
                onPressed: () {
                  setState(() {
                    _displayedMyPlacesCount += 10;
                  });
                },
              ),
          ],
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Созданные маршруты',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_myRoutes.length}',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_myRoutesLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_myRoutes.isEmpty)
            _buildProfileEmptyBlock(
              icon: Icons.route_outlined,
              title: 'У вас ещё нет маршрутов',
              subtitle: 'Соберите маршрут из двух или более мест',
            )
          else ...[
            ..._myRoutes.take(_displayedMyRoutesCount).map(_buildMyRouteCard),
            if (_myRoutes.length > _displayedMyRoutesCount)
              _buildProfileShowMoreButton(
                onPressed: () {
                  setState(() {
                    _displayedMyRoutesCount += 10;
                  });
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileShowMoreButton({required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Показать еще',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStatCard({
    required IconData icon,
    required String title,
    required String count,
  }) {
    final width = (MediaQuery.of(context).size.width - 56) / 3;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      width: width,
      height: 100,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            count,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_isGuest) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, size: 80, color: Colors.grey[400]),
                SizedBox(height: 20),
                Text(
                  'Вы не авторизованы',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Войдите в аккаунт, чтобы\nуправлять профилем',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      context.router.root.push(const LoginRoute());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Войти',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Выйти',
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setModalState) {
                      return DraggableScrollableSheet(
                        initialChildSize: 0.9,
                        minChildSize: 0.5,
                        maxChildSize: 0.95,
                        expand: false,
                        builder: (context, scrollController) {
                          return Container(
                            padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
                            child: Form(
                              key: _formKey,
                              child: ListView(
                                controller: scrollController,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'Редактирование профиля',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 30),
                                  Center(
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey[200],
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 10,
                                                offset: Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: _image != null
                                                ? (kIsWeb
                                                      ? Image.network(
                                                          _image!.path,
                                                          fit: BoxFit.cover,
                                                          width: 120,
                                                          height: 120,
                                                        )
                                                      : Image.file(
                                                          File(_image!.path),
                                                          fit: BoxFit.cover,
                                                          width: 120,
                                                          height: 120,
                                                        ))
                                                : (_currentUser?.avatar !=
                                                          null &&
                                                      _currentUser!
                                                          .avatar!
                                                          .isNotEmpty)
                                                ? Image.network(
                                                    '${ApiConstants.baseUrl}${_currentUser!.avatar}',
                                                    fit: BoxFit.cover,
                                                    width: 120,
                                                    height: 120,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return Icon(
                                                            Icons.person,
                                                            size: 60,
                                                            color: Colors
                                                                .grey[400],
                                                          );
                                                        },
                                                    loadingBuilder:
                                                        (
                                                          context,
                                                          child,
                                                          loadingProgress,
                                                        ) {
                                                          if (loadingProgress ==
                                                              null)
                                                            return child;
                                                          return Center(
                                                            child: CircularProgressIndicator(
                                                              value:
                                                                  loadingProgress
                                                                          .expectedTotalBytes !=
                                                                      null
                                                                  ? loadingProgress
                                                                            .cumulativeBytesLoaded /
                                                                        loadingProgress
                                                                            .expectedTotalBytes!
                                                                  : null,
                                                            ),
                                                          );
                                                        },
                                                  )
                                                : Icon(
                                                    Icons.person,
                                                    size: 60,
                                                    color: Colors.grey[400],
                                                  ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: GestureDetector(
                                            onTap: () {
                                              _pickImage(setModalState);
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(
                                                  255,
                                                  53,
                                                  20,
                                                  82,
                                                ),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.camera_alt,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 40),
                                  Text(
                                    'Личная информация',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  _buildTextField(
                                    controller: _nameController,
                                    label: 'Имя',
                                    icon: Icons.person_outline,
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Введите имя';
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 15),
                                  _buildTextField(
                                    controller: _surnameController,
                                    label: 'Фамилия',
                                    icon: Icons.person_outline,
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Введите фамилию';
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 15),
                                  _buildTextField(
                                    controller: _patronymicController,
                                    label: 'Отчество',
                                    icon: Icons.person_outline,
                                  ),
                                  SizedBox(height: 15),
                                  _buildTextField(
                                    controller: _emailController,
                                    label: 'Email',
                                    icon: Icons.email_outlined,
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Введите email';
                                      if (!value.contains('@'))
                                        return 'Введите корректный email';
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 30),
                                  Text(
                                    'Безопасность',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  _buildTextField(
                                    controller: _passwordController,
                                    label: 'Новый пароль',
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    isPasswordVisible: isPasswordVisible,
                                    onVisibilityToggle: () {
                                      setModalState(() {
                                        isPasswordVisible = !isPasswordVisible;
                                      });
                                    },
                                    validator: (value) {
                                      if (value != null &&
                                          value.isNotEmpty &&
                                          value.length < 6) {
                                        return 'Пароль должен быть не менее 6 символов';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 15),
                                  _buildTextField(
                                    controller: _passwordController2,
                                    label: 'Повторите пароль',
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    isPasswordVisible: isPasswordVisible,
                                    onVisibilityToggle: () {
                                      setModalState(() {
                                        isPasswordVisible = !isPasswordVisible;
                                      });
                                    },
                                    validator: (value) {
                                      if (value != _passwordController.text) {
                                        return 'Пароли не совпадают';
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: 40),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (_formKey.currentState!.validate()) {
                                          _formKey.currentState!.save();
                                          final result = await _profileService
                                              .updateuserMe(
                                                _image,
                                                _nameController.text,
                                                _surnameController.text,
                                                _patronymicController.text,
                                                _emailController.text,
                                                _passwordController
                                                        .text
                                                        .isNotEmpty
                                                    ? _passwordController.text
                                                    : null,
                                              );
                                          if (result) {
                                            Navigator.pop(context);
                                            showFloatingSnackBar(
                                              context,
                                              'Профиль сохранен',
                                            );
                                            _loadUser();
                                          } else {
                                            showFloatingSnackBar(
                                              context,
                                              'Ошибка сохранения',
                                            );
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                          255,
                                          53,
                                          20,
                                          82,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Сохранить изменения',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
            icon: Icon(Icons.settings, color: Colors.white),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final role = _currentUser?.id_role ?? 1;
          final bool isModerator = role == 3 || role == 2;
          final bool isAdmin = role == 2;
          final int tabCount = 1 + (isModerator ? 1 : 0) + (isAdmin ? 1 : 0);
          return DefaultTabController(
            length: tabCount,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(gradient: AppColors.mainGradient),
                  width: double.infinity,
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey,
                          ),
                          child:
                              (_currentUser != null &&
                                  _currentUser!.avatar != null &&
                                  _currentUser!.avatar!.isNotEmpty)
                              ? ClipOval(
                                  child: Image.network(
                                    '${ApiConstants.baseUrl}${_currentUser!.avatar}',
                                    fit: BoxFit.cover,
                                    width: 120,
                                    height: 120,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey[300],
                                      );
                                    },
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey[300],
                                ),
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        _currentUser != null
                            ? '${_currentUser!.first_name} ${_currentUser!.last_name}'
                            : 'Загрузка...',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (isAdmin || isModerator) ...[
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isAdmin ? Colors.red : Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAdmin ? Icons.shield : Icons.verified_user,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isAdmin ? 'Администратор' : 'Модератор',
                                  style: const TextStyle(
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
                      const SizedBox(height: 20),
                      Text(
                        'Добавляй, исследуй, делись',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildProfileStatCard(
                              icon: Icons.favorite,
                              title: 'В избранном',
                              count: '$_favoritesCount',
                            ),
                            _buildProfileStatCard(
                              icon: Icons.add_location,
                              title: 'Создано мест',
                              count: '${_myPlaces.length}',
                            ),
                            _buildProfileStatCard(
                              icon: Icons.route_rounded,
                              title: 'Создано маршрутов',
                              count: '${_myRoutes.length}',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.black,
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorWeight: 2,
                        indicatorPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        dividerColor: Colors.transparent,
                        tabs: [
                          const Tab(height: 45, child: Text('Места')),
                          if (isModerator)
                            const Tab(height: 45, child: Text('Модерация')),
                          if (isAdmin)
                            const Tab(height: 45, child: Text('Админ панель')),
                        ],
                      ),
                      Divider(
                        color: const Color.fromARGB(255, 58, 57, 57),
                        thickness: 0.6,
                        height: 1,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: TabBarView(
                      children: [
                        _buildProfileMainTab(),

                        if (isModerator)
                          RefreshIndicator(
                            onRefresh: _refreshProfileData,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(20),
                              children: [
                                const Text(
                                  'Панель модератора',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.3,
                                  children: [
                                    _buildDashboardCard(
                                      title: 'На модерации',
                                      count: '$_pendingCount',
                                      icon: Icons.pending_actions,
                                      color: Colors.orange,
                                      onTap: () =>
                                          _showModerationPage('pending'),
                                    ),
                                    _buildDashboardCard(
                                      title: 'Жалобы',
                                      count: '$_reportsCount',
                                      icon: Icons.report_problem,
                                      color: Colors.red,
                                      onTap: () =>
                                          _showModerationPage('reports'),
                                    ),
                                    _buildDashboardCard(
                                      title: 'Одобрено',
                                      count: '$_approvedCount',
                                      icon: Icons.check_circle,
                                      color: Colors.green,
                                      onTap: () =>
                                          _showModerationPage('approved'),
                                    ),
                                    _buildDashboardCard(
                                      title: 'Отклонено',
                                      count: '$_declinedCount',
                                      icon: Icons.cancel,
                                      color: Colors.grey,
                                      onTap: () =>
                                          _showModerationPage('declined'),
                                    ),
                                    _buildDashboardCard(
                                      title: 'Пользователи',
                                      count: '$_usersCount',
                                      icon: Icons.people,
                                      color: Colors.blue,
                                      onTap: () => _showAdminListPage('users'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 120),
                              ],
                            ),
                          ),

                        if (isAdmin)
                          RefreshIndicator(
                            onRefresh: _refreshProfileData,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                top: 20,
                                left: 20,
                                right: 20,
                                bottom: 100,
                              ),
                              children: [
                                const Text(
                                  'Администрирование',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.3,
                                  children: [
                                    _buildDashboardCard(
                                      title: 'Пользователи',
                                      count: '$_usersCount',
                                      icon: Icons.people,
                                      color: Colors.blue,
                                      onTap: () => _showAdminListPage('users'),
                                    ),
                                    _buildDashboardCard(
                                      title: 'Все места',
                                      count: '$_allPlacesCount',
                                      icon: Icons.map,
                                      color: Colors.purple,
                                      onTap: () => _showAdminListPage('places'),
                                    ),
                                    _buildDashboardCard(
                                      title: 'Все маршруты',
                                      count: '${_allRoutes.length}',
                                      icon: Icons.route_rounded,
                                      color: Colors.indigo,
                                      onTap: () => _showAdminListPage('routes'),
                                    ),
                                    _buildDashboardCard(
                                      title: 'Категории',
                                      count: '$_categoriesCount',
                                      icon: Icons.category,
                                      color: Colors.teal,
                                      onTap: () =>
                                          _showManageCategoriesDialog(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 120),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showManageCategoriesDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (ctx, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Управление категориями',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add, color: Colors.teal),
                              onPressed: () {
                                _showEditOrCreateCategoryDialog(
                                  null,
                                  setModalState,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _categories.isEmpty
                          ? Center(
                              child: Text(
                                'Нет категорий',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 18,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.category,
                                    color: Colors.teal,
                                  ),
                                  title: Text(
                                    category.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () {
                                          _showEditOrCreateCategoryDialog(
                                            category,
                                            setModalState,
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          final success = await _adminService
                                              .deleteCategory(category.id);
                                          if (success) {
                                            await _loadAdminData();
                                            setModalState(() {});
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showEditOrCreateCategoryDialog(
    CategoryModel? category,
    StateSetter setModalState,
  ) {
    final TextEditingController categoryController = TextEditingController(
      text: category?.name ?? '',
    );
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category == null
                      ? 'Добавить категорию'
                      : 'Изменить категорию',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    hintText: 'Название категории',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: AppColors.accentColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Отмена',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final name = categoryController.text.trim();
                        if (name.isNotEmpty) {
                          bool success;
                          if (category == null) {
                            success = await _adminService.addCategory(name);
                          } else {
                            success = await _adminService.updateCategory(
                              category.id,
                              name,
                            );
                          }
                          Navigator.pop(context);
                          if (success) {
                            await _loadAdminData();
                            setModalState(() {});
                          }
                        }
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
                        'Сохранить',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showModerationPage(String type) {
    String title;
    IconData icon;
    Color color;

    switch (type) {
      case 'pending':
        title = 'На модерации';
        icon = Icons.pending_actions;
        color = Colors.orange;
        break;
      case 'reports':
        title = 'Жалобы';
        icon = Icons.report_problem;
        color = Colors.red;
        break;
      case 'approved':
        title = 'Одобрено';
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'declined':
        title = 'Отклонено';
        icon = Icons.cancel;
        color = Colors.grey;
        break;
      default:
        title = '';
        icon = Icons.info;
        color = Colors.blue;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            List<dynamic> filteredItems = [];
            if (type == 'pending') {
              filteredItems = _pendingPlaces
                  .where(
                    (p) =>
                        p.name.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ||
                        p.type.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ),
                  )
                  .toList();
            } else if (type == 'reports') {
              filteredItems = _reports;
            } else if (type == 'approved') {
              filteredItems = _approvedPlaces
                  .where(
                    (p) =>
                        p.name.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ||
                        p.type.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ),
                  )
                  .toList();
            } else if (type == 'declined') {
              filteredItems = _declinedPlaces
                  .where(
                    (p) =>
                        p.name.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ||
                        p.type.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ),
                  )
                  .toList();
            }
            int currentItemCount = filteredItems.length;

            return DraggableScrollableSheet(
              initialChildSize: 0.92,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: color, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$currentItemCount элементов',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (type != 'reports')
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: TextField(
                          onChanged: (val) {
                            setModalState(() {
                              searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Поиск...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                    const Divider(height: 1),
                    Expanded(
                      child: currentItemCount == 0
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, size: 64, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Пусто',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: currentItemCount + 1,
                              separatorBuilder: (_, index) =>
                                  index < currentItemCount - 1
                                  ? const SizedBox(height: 12)
                                  : const SizedBox.shrink(),
                              itemBuilder: (context, index) {
                                if (index == currentItemCount) {
                                  return const SizedBox(height: 100);
                                }
                                if (type == 'pending') {
                                  return _buildRealPendingItem(
                                    filteredItems[index] as PlotsModel,
                                    setModalState,
                                  );
                                } else if (type == 'reports') {
                                  return _buildRealReportItem(
                                    filteredItems[index] as ReportPlacesModel,
                                    setModalState,
                                  );
                                } else if (type == 'approved') {
                                  return _buildRealPlaceStatusItem(
                                    filteredItems[index] as PlotsModel,
                                    Colors.green,
                                    'Одобрено',
                                  );
                                } else {
                                  return _buildRealPlaceStatusItem(
                                    filteredItems[index] as PlotsModel,
                                    Colors.grey,
                                    'Отклонено',
                                  );
                                }
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRealPendingItem(PlotsModel place, StateSetter setModalState) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        context.router.push(DetailPlaceRoute(plot: place));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                      image: place.image.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(
                                '${ApiConstants.baseUrl}${place.image}',
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: place.image.isEmpty
                        ? Icon(Icons.image, color: Colors.grey[400])
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (place.type.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  place.type,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.accentColor,
                                  ),
                                ),
                              ),
                            if (place.authorName.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                place.authorName,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final ok = await _adminService.updatePlaceStatus(
                            place.id,
                            2,
                          );
                          if (ok) {
                            await _loadAdminData();
                            setModalState(() {});
                            showFloatingSnackBar(
                              context,
                              '"${place.name}" одобрено ✅',
                            );
                          }
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Одобрить'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final ok = await _adminService.updatePlaceStatus(
                            place.id,
                            3,
                          );
                          if (ok) {
                            await _loadAdminData();
                            setModalState(() {});
                            showFloatingSnackBar(
                              context,
                              '"${place.name}" отклонено ❌',
                            );
                          }
                        },
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Отклонить'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  Widget _buildRealReportItem(
    ReportPlacesModel report,
    StateSetter setModalState,
  ) {
    return InkWell(
      onTap: () async {
        final place = await _adminService.getPlaceById(report.idPlace);
        if (place != null && mounted) {
          Navigator.pop(context);
          context.router.push(DetailPlaceRoute(plot: place));
        } else {
          showFloatingSnackBar(context, 'Место не найдено');
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.flag, color: Colors.red[400], size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Место #${report.idPlace}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Тип жалобы: ${report.idTypeReport}',
                          style: TextStyle(
                            color: Colors.red[300],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  report.report.isNotEmpty ? report.report : 'Без описания',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _adminService.deletePlace(report.idPlace);
                          await _adminService.deleteReport(report.id);
                          await _loadAdminData();
                          setModalState(() {});
                          showFloatingSnackBar(
                            context,
                            'Выполнено (место удалено) 🗑',
                          );
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Выполнить'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _adminService.deleteReport(report.id);
                          await _loadAdminData();
                          setModalState(() {});
                          showFloatingSnackBar(context, 'Жалоба отклонена ✓');
                        },
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Отклонить'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  Widget _buildRealPlaceStatusItem(
    PlotsModel place,
    Color statusColor,
    String statusLabel,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        context.router.push(DetailPlaceRoute(plot: place));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[200],
              image: place.image.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(
                        '${ApiConstants.baseUrl}${place.image}',
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: place.image.isEmpty
                ? Icon(Icons.image, color: Colors.grey[400], size: 24)
                : null,
          ),
          title: Text(
            place.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Row(
            children: [
              Icon(Icons.circle, size: 10, color: statusColor),
              const SizedBox(width: 4),
              Text(
                statusLabel,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              if (place.type.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  place.type,
                  style: TextStyle(fontSize: 12, color: AppColors.accentColor),
                ),
              ],
            ],
          ),
          trailing: Text(
            place.authorName,
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
        ),
      ),
    );
  }

  void _showAdminListPage(String type) {
    final bool isUsers = type == 'users';
    final bool isRoutes = type == 'routes';
    final String title = isUsers
        ? 'Пользователи'
        : isRoutes
        ? 'Все маршруты'
        : 'Все места';
    final IconData icon = isUsers
        ? Icons.people
        : isRoutes
        ? Icons.route_rounded
        : Icons.map;
    final Color color = isUsers
        ? Colors.blue
        : isRoutes
        ? Colors.indigo
        : Colors.purple;
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final List<UserModel> filteredUsers = _users.where((u) {
              final val = '${u.first_name} ${u.last_name} ${u.email}'
                  .toLowerCase();
              return val.contains(searchQuery.toLowerCase());
            }).toList();

            final List<PlotsModel> filteredPlaces = _allPlaces.where((p) {
              final val = '${p.name} ${p.status} ${p.type} ${p.authorName}'
                  .toLowerCase();
              return val.contains(searchQuery.toLowerCase());
            }).toList();

            final List<RouteModel> filteredRoutes = _allRoutes.where((r) {
              final places = r.places.map((p) => p.name).join(' ');
              final val = '${r.name} ${r.authorName} $places'.toLowerCase();
              return val.contains(searchQuery.toLowerCase());
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.92,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (ctx, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: color, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                isUsers
                                    ? '${filteredUsers.length} пользователей'
                                    : isRoutes
                                    ? '${filteredRoutes.length} маршрутов'
                                    : '${filteredPlaces.length} мест',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: TextField(
                        onChanged: (val) {
                          setModalState(() {
                            searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Поиск...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: isUsers
                          ? ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredUsers.length + 1,
                              separatorBuilder: (_, index) =>
                                  index < filteredUsers.length - 1
                                  ? const SizedBox(height: 8)
                                  : const SizedBox.shrink(),
                              itemBuilder: (context, index) {
                                if (index == filteredUsers.length) {
                                  return const SizedBox(height: 120);
                                }
                                return _buildUserItem(
                                  filteredUsers[index],
                                  setModalState,
                                );
                              },
                            )
                          : isRoutes
                          ? ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredRoutes.length + 1,
                              separatorBuilder: (_, index) =>
                                  index < filteredRoutes.length - 1
                                  ? const SizedBox(height: 8)
                                  : const SizedBox.shrink(),
                              itemBuilder: (context, index) {
                                if (index == filteredRoutes.length) {
                                  return const SizedBox(height: 120);
                                }
                                return _buildAdminRouteItem(
                                  filteredRoutes[index],
                                  setModalState,
                                );
                              },
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredPlaces.length + 1,
                              separatorBuilder: (_, index) =>
                                  index < filteredPlaces.length - 1
                                  ? const SizedBox(height: 8)
                                  : const SizedBox.shrink(),
                              itemBuilder: (context, index) {
                                if (index == filteredPlaces.length) {
                                  return const SizedBox(height: 120);
                                }
                                return _buildAdminPlaceItem(
                                  filteredPlaces[index],
                                  setModalState,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUserItem(UserModel user, StateSetter setModalState) {
    final roleName = user.id_role == 2
        ? 'Админ'
        : user.id_role == 3
        ? 'Модератор'
        : 'Пользователь';
    final roleColor = user.id_role == 2
        ? Colors.red
        : user.id_role == 3
        ? Colors.orange
        : Colors.blue;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: user.banned
              ? Colors.red.withOpacity(0.3)
              : Colors.grey.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: user.banned
              ? Colors.red[100]
              : roleColor.withOpacity(0.15),
          child: Text(
            user.first_name.isNotEmpty ? user.first_name[0].toUpperCase() : '?',
            style: TextStyle(
              color: user.banned ? Colors.red : roleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${user.first_name} ${user.last_name}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            decoration: user.banned ? TextDecoration.lineThrough : null,
            color: user.banned ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                roleName,
                style: TextStyle(
                  fontSize: 10,
                  color: roleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                user.email,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing:
            (_currentUser?.id_role == 3 && user.id_role != 1) ||
                user.id_role == 2
            ? null
            : IconButton(
                icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (ctx) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '${user.first_name} ${user.last_name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              user.email,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            if (_currentUser?.id_role == 2) ...[
                              ListTile(
                                leading: const Icon(Icons.shield_outlined, color: Colors.blue),
                                title: const Text('Сделать пользователем'),
                                onTap: () async {
                                  Navigator.pop(ctx);
                                  final ok = await _adminService.updateUserRole(user.id, 1);
                                  if (ok) {
                                    await _loadAdminData();
                                    setModalState(() {});
                                    showFloatingSnackBar(context, 'Роль обновлена');
                                  } else {
                                    showFloatingSnackBar(context, 'Ошибка');
                                  }
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.shield_outlined, color: Colors.orange),
                                title: const Text('Сделать модератором'),
                                onTap: () async {
                                  Navigator.pop(ctx);
                                  final ok = await _adminService.updateUserRole(user.id, 3);
                                  if (ok) {
                                    await _loadAdminData();
                                    setModalState(() {});
                                    showFloatingSnackBar(context, 'Роль обновлена');
                                  } else {
                                    showFloatingSnackBar(context, 'Ошибка');
                                  }
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.shield_outlined, color: Colors.red),
                                title: const Text('Сделать администратором'),
                                onTap: () async {
                                  Navigator.pop(ctx);
                                  final ok = await _adminService.updateUserRole(user.id, 2);
                                  if (ok) {
                                    await _loadAdminData();
                                    setModalState(() {});
                                    showFloatingSnackBar(context, 'Роль обновлена');
                                  } else {
                                    showFloatingSnackBar(context, 'Ошибка');
                                  }
                                },
                              ),
                              const Divider(),
                            ],
                            ListTile(
                              leading: Icon(
                                user.banned ? Icons.check_circle_outline : Icons.block_outlined,
                                color: user.banned ? Colors.green : Colors.red,
                              ),
                              title: Text(
                                user.banned ? 'Разблокировать' : 'Заблокировать',
                                style: TextStyle(color: user.banned ? Colors.green : Colors.red),
                              ),
                              onTap: () async {
                                Navigator.pop(ctx);
                                final ok = await _adminService.toggleUserBan(user.id, !user.banned);
                                if (ok) {
                                  await _loadAdminData();
                                  setModalState(() {});
                                  showFloatingSnackBar(
                                    context,
                                    user.banned
                                        ? '${user.first_name} разбанен'
                                        : '${user.first_name} забанен',
                                  );
                                } else {
                                  showFloatingSnackBar(context, 'Ошибка');
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildAdminRouteItem(RouteModel route, StateSetter setModalState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.route_rounded, color: Colors.indigo),
        ),
        title: Text(
          route.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${route.places.length} мест · ${route.authorName.isNotEmpty ? route.authorName : 'Пользователь'}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (route.places.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                route.places.map((p) => p.name).join(' → '),
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Удалить маршрут?'),
                    content: Text('Маршрут "${route.name}" будет удалён безвозвратно.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Удалить',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ) ??
                false;
            if (!confirm) return;

            final ok = await _adminService.deleteRouteAdmin(route.id);
            if (ok) {
              await _loadAdminData();
              setModalState(() {});
              showFloatingSnackBar(context, 'Маршрут удалён');
            } else {
              showFloatingSnackBar(context, 'Ошибка при удалении маршрута');
            }
          },
        ),
        onTap: () {
          Navigator.pop(context);
          context.router.push(DetailRouteRoute(route: route));
        },
      ),
    );
  }

  Widget _buildAdminPlaceItem(PlotsModel place, StateSetter setModalState) {
    final statusColor = place.status.contains('модер')
        ? Colors.orange
        : place.status.contains('Одобр')
        ? Colors.green
        : Colors.grey;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[200],
            image: place.image.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(
                      '${ApiConstants.baseUrl}${place.image}',
                    ),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: place.image.isEmpty
              ? Icon(Icons.image, color: Colors.grey[400], size: 22)
              : null,
        ),
        title: Text(
          place.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 8, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  place.status.isNotEmpty ? place.status : 'На модерации',
                  style: TextStyle(fontSize: 11, color: statusColor),
                ),
                if (place.type.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    place.type,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 10,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: AddressText(
                    initialLocation: place.location,
                    coordinates: place.coordinates,
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              place.authorName,
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) {
                    final s = place.status.toLowerCase();
                    final isApproved = s.contains('одобр') || s.contains('актив') || s.contains('подтвер');
                    final isRejected = s.contains('отклон') || s.contains('отказ');

                    return Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            place.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          if (!isApproved)
                            ListTile(
                              leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                              title: const Text('Одобрить место'),
                              onTap: () async {
                                Navigator.pop(ctx);
                                final ok = await _adminService.updatePlaceStatus(place.id, 2);
                                if (ok) {
                                  await _loadAdminData();
                                  setModalState(() {});
                                  showFloatingSnackBar(context, 'Место одобрено');
                                }
                              },
                            ),
                          if (!isRejected)
                            ListTile(
                              leading: const Icon(Icons.block_outlined, color: Colors.orange),
                              title: const Text('Заблокировать / Отклонить'),
                              onTap: () async {
                                Navigator.pop(ctx);
                                final ok = await _adminService.updatePlaceStatus(place.id, 3);
                                if (ok) {
                                  await _loadAdminData();
                                  setModalState(() {});
                                  showFloatingSnackBar(context, 'Место заблокировано');
                                }
                              },
                            ),
                          ListTile(
                            leading: const Icon(Icons.delete_outline, color: Colors.red),
                            title: const Text(
                              'Удалить безвозвратно',
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: () async {
                              Navigator.pop(ctx);
                              final ok = await _adminService.deletePlace(place.id);
                              if (ok) {
                                  await _loadAdminData();
                                  setModalState(() {});
                                  showFloatingSnackBar(context, 'Место удалено полностью');
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.pop(context);
          context.router.push(DetailPlaceRoute(plot: place));
        },
      ),
    );
  }
}

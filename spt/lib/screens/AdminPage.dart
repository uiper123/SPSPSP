import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:spt/models/user_model.dart';
import 'package:spt/models/plots_model.dart';
import 'package:spt/serv/admin_serv.dart';
import 'package:spt/core/constant/colors.dart';
import 'package:spt/core/constant/api_constants.dart';
import 'package:spt/serv/profile_serv.dart';
import 'package:spt/core/utils/snackbar_helper.dart';

@RoutePage()
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final AdminService _adminService = AdminService();
  final ProfileService _profileService = ProfileService();

  UserModel? _currentUser;
  bool _isLoading = true;

  List<PlotsModel> _allPlaces = [];
  List<UserModel> _users = [];
  List<ReportPlacesModel> _reports = [];
  String _placeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = await _profileService.getuserMe();

    if (user == null || (user.id_role != 2 && user.id_role != 3)) {
      if (mounted) context.router.back();
      return;
    }

    _currentUser = user;

    final pending = await _adminService.getPlacesByStatus(1);
    final approved = await _adminService.getPlacesByStatus(2);
    final rejected = await _adminService.getPlacesByStatus(3);
    final places = [...pending, ...approved, ...rejected];
    final reports = await _adminService.getReports();
    List<UserModel> usersList = [];
    if (user.id_role == 2) {
      usersList = await _adminService.getUsers();
    }

    setState(() {
      _allPlaces = places;
      _reports = reports;
      _users = usersList;
      _isLoading = false;
    });
  }

  Future<void> _approvePlace(int id) async {
    final success = await _adminService.updatePlaceStatus(
      id,
      2,
    ); 
    if (success) {
      showFloatingSnackBar(context, 'Место одобрено');
      _loadData();
    } else {
      showFloatingSnackBar(context, 'Ошибка при одобрении места');
    }
  }

  Future<void> _rejectPlace(int id) async {
    final success = await _adminService.updatePlaceStatus(
      id,
      3,
    ); 
    if (success) {
      showFloatingSnackBar(context, 'Место отклонено');
      _loadData();
    } else {
      showFloatingSnackBar(context, 'Ошибка при отклонении места');
    }
  }

  Future<void> _deleteReport(int id) async {
    final success = await _adminService.deleteReport(id);
    if (success) {
      showFloatingSnackBar(context, 'Жалоба удалена');
      _loadData();
    } else {
      showFloatingSnackBar(context, 'Ошибка при удалении жалобы');
    }
  }

  Future<void> _toggleUserBan(int id, bool currentStatus) async {
    final success = await _adminService.toggleUserBan(id, !currentStatus);
    if (success) {
      showFloatingSnackBar(
        context,
        !currentStatus ? 'Пользователь забанен' : 'Пользователь разбанен',
      );
      _loadData();
    } else {
      showFloatingSnackBar(context, 'Ошибка');
    }
  }

  Future<void> _updateUserRole(int id, int roleId) async {
    final success = await _adminService.updateUserRole(id, roleId);
    if (success) {
      showFloatingSnackBar(context, 'Роль пользователя успешно обновлена');
      _loadData();
    } else {
      showFloatingSnackBar(context, 'Ошибка при обновлении роли');
    }
  }

  void _showUserActionSheet(BuildContext context, UserModel user) {
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
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateUserRole(user.id, 1);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: Colors.orange),
                  title: const Text('Сделать модератором'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateUserRole(user.id, 3);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: Colors.red),
                  title: const Text('Сделать администратором'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateUserRole(user.id, 2);
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
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleUserBan(user.id, user.banned);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  List<PlotsModel> _getFilteredPlaces() {
    return _allPlaces.where((place) {
      final s = place.status.toLowerCase();
      if (_placeFilter == 'pending') {
        return place.status.isEmpty || s.contains('модер');
      } else if (_placeFilter == 'approved') {
        return s.contains('одобр') || s.contains('актив') || s.contains('подтвер');
      } else if (_placeFilter == 'rejected') {
        return s.contains('отклон') || s.contains('отказ');
      }
      return true;
    }).toList();
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('all', 'Все (${_allPlaces.length})'),
          const SizedBox(width: 8),
          _buildFilterChip(
            'pending',
            'На модерации (${_allPlaces.where((p) => p.status.isEmpty || p.status.toLowerCase().contains('модер')).length})',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'approved',
            'Одобренные (${_allPlaces.where((p) => p.status.toLowerCase().contains('одобр') || p.status.toLowerCase().contains('актив') || p.status.toLowerCase().contains('подтвер')).length})',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'rejected',
            'Отклоненные (${_allPlaces.where((p) => p.status.toLowerCase().contains('отклон') || p.status.toLowerCase().contains('отказ')).length})',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isSelected = _placeFilter == filter;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.accentColor,
      backgroundColor: Colors.grey[200],
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _placeFilter = filter;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Панель управления')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: _currentUser?.id_role == 2 ? 3 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _currentUser?.id_role == 2
                ? 'Панель администратора'
                : 'Панель модератора',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.accentColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.accentColor,
            tabs: [
              Tab(text: 'Места (${_allPlaces.length})'),
              Tab(text: 'Жалобы (${_reports.length})'),
              if (_currentUser?.id_role == 2)
                Tab(text: 'Пользователи (${_users.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPlacesTab(),
            _buildReportsTab(),
            if (_currentUser?.id_role == 2) _buildUsersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacesTab() {
    final filtered = _getFilteredPlaces();
    return Column(
      children: [
        _buildFilterChips(),
        const Divider(height: 1),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Нет мест в этой категории'))
              : ListView.builder(
                  itemCount: filtered.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final place = filtered[index];
                    final s = place.status.toLowerCase();
                    final isPending = place.status.isEmpty || s.contains('модер');
                    final isApproved = s.contains('одобр') || s.contains('актив') || s.contains('подтвер');
                    final isRejected = s.contains('отклон') || s.contains('отказ');

                    Color statusColor = Colors.orange;
                    String statusText = 'На модерации';
                    if (isApproved) {
                      statusColor = Colors.green;
                      statusText = 'Одобрено';
                    } else if (isRejected) {
                      statusColor = Colors.red;
                      statusText = 'Отклонено';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        place.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.circle, size: 8, color: statusColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            statusText,
                                            style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
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
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              place.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isPending || isApproved)
                                  TextButton(
                                    onPressed: () => _rejectPlace(place.id),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Отклонить'),
                                  ),
                                if (isPending || isApproved)
                                  const SizedBox(width: 8),
                                if (isPending || isRejected)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => _approvePlace(place.id),
                                    child: const Text('Одобрить'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReportsTab() {
    if (_reports.isEmpty) {
      return Center(child: Text('Нет активных жалоб'));
    }
    return ListView.builder(
      itemCount: _reports.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final report = _reports[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              child: const Icon(
                Icons.report_gmailerrorred_rounded,
                color: Colors.red,
              ),
            ),
            title: Text(
              'Жалоба на место ID: ${report.idPlace}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  report.report,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Создано: ${report.createdAt.toLocal().toString().split('.')[0]}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              tooltip: 'Решить жалобу',
              onPressed: () => _deleteReport(report.id),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUsersTab() {
    if (_users.isEmpty) {
      return Center(child: Text('Нет загруженных пользователей'));
    }
    return ListView.builder(
      itemCount: _users.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final u = _users[index];
        final roleName = u.id_role == 2
            ? 'Админ'
            : u.id_role == 3
            ? 'Модератор'
            : 'Пользователь';
        final roleColor = u.id_role == 2
            ? Colors.red
            : u.id_role == 3
            ? Colors.orange
            : Colors.blue;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: u.banned
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
              backgroundColor: u.banned
                  ? Colors.red[100]
                  : roleColor.withOpacity(0.15),
              child: Text(
                u.first_name.isNotEmpty ? u.first_name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: u.banned ? Colors.red : roleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              '${u.first_name} ${u.last_name}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                decoration: u.banned ? TextDecoration.lineThrough : null,
                color: u.banned ? Colors.grey : Colors.black87,
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
                    u.email,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
              onPressed: () => _showUserActionSheet(context, u),
            ),
          ),
        );
      },
    );
  }
}

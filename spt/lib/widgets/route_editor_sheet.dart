import 'package:flutter/material.dart';
import 'package:spt/core/constant/api_constants.dart';
import 'package:spt/core/constant/colors.dart';
import 'package:spt/models/plots_model.dart';
import 'package:spt/models/route_model.dart';
import 'package:spt/serv/route_serv.dart';
import 'package:spt/serv/searchPlots_serv.dart';
import 'package:spt/core/utils/snackbar_helper.dart';

class RouteEditorSheet extends StatefulWidget {
  final RouteModel? route;
  final void Function(RouteModel) onSaved;

  const RouteEditorSheet({super.key, this.route, required this.onSaved});

  @override
  State<RouteEditorSheet> createState() => _RouteEditorSheetState();
}

class _RouteEditorSheetState extends State<RouteEditorSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final RouteService _routeService = RouteService();
  final SearchPlots _searchService = SearchPlots();

  List<PlotsModel> _searchResults = [];
  final List<PlotsModel> _selectedPlaces = [];
  bool _isSearching = false;
  bool _isSaving = false;

  bool get _isEditing => widget.route != null;

  @override
  void initState() {
    super.initState();
    final route = widget.route;
    if (route != null) {
      _nameController.text = route.name;
      _descController.text = route.description ?? '';
      _selectedPlaces.addAll(route.places.map(_placeFromRouteItem));
    }
    _loadAllPlaces();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  PlotsModel _placeFromRouteItem(RoutePlaceItem place) {
    return PlotsModel(
      id: place.id,
      name: place.name,
      description: '',
      image: place.image,
      location: place.location,
      coordinates: place.coordinates,
      type: '',
      status: '',
      id_user: 0,
      authorName: '',
    );
  }

  Future<void> _loadAllPlaces() async {
    setState(() => _isSearching = true);
    final results = await _searchService.searchPlots(idStatus: 2);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      _loadAllPlaces();
      return;
    }
    setState(() => _isSearching = true);
    final results = await _searchService.searchPlots(name: query, idStatus: 2);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _showMessage(String message) {
    showFloatingSnackBar(context, message);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final description = _descController.text.trim();
    final placeIds = _selectedPlaces.map((p) => p.id).toList();
    if (name.isEmpty) {
      _showMessage('Введите название маршрута');
      return;
    }
    if (placeIds.length < 2) {
      _showMessage('Маршрут должен содержать минимум два места');
      return;
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);
    final saved = _isEditing
        ? await _routeService.updateRoute(
            widget.route!.id,
            name,
            description,
            placeIds,
          )
        : await _routeService.createRoute(
            name,
            description.isNotEmpty ? description : null,
            placeIds,
          );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (saved != null) {
      widget.onSaved(saved);
      navigator.pop();
    } else {
      showFloatingSnackBar(
        context,
        _routeService.lastError ??
            (_isEditing
                ? 'Не удалось сохранить маршрут'
                : 'Не удалось создать маршрут'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 16),
                  Text(
                    _isEditing ? 'Изменить маршрут' : 'Новый маршрут',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _nameController,
                    hint: 'Название маршрута',
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _descController,
                    hint: 'Описание (необязательно)',
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Добавить места',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    onChanged: _searchPlaces,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      hintText: 'Поиск мест...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  if (_selectedPlaces.isNotEmpty) ...[
                    const Text(
                      'Маршрут',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedPlaces.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final item = _selectedPlaces.removeAt(oldIndex);
                          _selectedPlaces.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final place = _selectedPlaces[index];
                        return _buildSelectedPlaceItem(place, index);
                      },
                    ),
                    const Divider(height: 24),
                  ],
                  if (_isSearching)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    ..._searchResults.map((place) {
                      final alreadyAdded = _selectedPlaces.any(
                        (p) => p.id == place.id,
                      );
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: place.image.isNotEmpty
                              ? Image.network(
                                  '${ApiConstants.baseUrl}${place.image}',
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image, size: 20),
                                  ),
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image, size: 20),
                                ),
                        ),
                        title: Text(
                          place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          place.type.isNotEmpty ? place.type : 'Без категории',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        trailing: alreadyAdded
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: AppColors.accentColor,
                                ),
                                onPressed: () {
                                  setState(() => _selectedPlaces.add(place));
                                },
                              ),
                      );
                    }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isEditing
                                  ? 'Сохранить изменения'
                                  : 'Сохранить маршрут',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectedPlaceItem(PlotsModel place, int index) {
    return Container(
      key: ValueKey(place.id),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: AppColors.accentColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              place.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.drag_handle, color: Colors.grey),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            onPressed: () => setState(() => _selectedPlaces.remove(place)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[100],
        hintText: hint,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

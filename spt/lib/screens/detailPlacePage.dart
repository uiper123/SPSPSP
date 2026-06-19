import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:spt/models/plots_model.dart';
import 'package:spt/models/comment_model.dart';
import 'package:spt/models/user_model.dart';
import 'package:spt/serv/comment_serv.dart';
import 'package:spt/serv/profile_serv.dart';
import 'package:spt/serv/favorites_serv.dart';
import 'package:spt/serv/report_serv.dart';
import 'package:spt/core/utils/snackbar_helper.dart';
import 'package:spt/routing/app_router.dart';
import 'package:spt/core/map_focus.dart';
import 'package:spt/serv/admin_serv.dart';
import 'package:spt/serv/category_serv.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:spt/core/constant/api_constants.dart';
import 'package:spt/core/constant/colors.dart';

@RoutePage()
class DetailPlacePage extends StatefulWidget {
  final PlotsModel plot;

  const DetailPlacePage({super.key, required this.plot});

  @override
  State<DetailPlacePage> createState() => _DetailPlacePageState();
}

class _DetailPlacePageState extends State<DetailPlacePage> {
  final List<Image> _images = [];
  List<CommentModel> _comments = [];
  bool _commentsLoading = true;
  UserModel? _currentUser;
  bool _isOwner = false;
  final TextEditingController _commentController = TextEditingController();
  final CommentService _commentService = CommentService();
  final FavoritesService _favoritesService = FavoritesService();
  int _selectedRating = 5;
  bool _isFavorite = false;
  final ReportService _reportService = ReportService();
  String _resolvedAddress = '';
  late PlotsModel _currentPlot;

  @override
  void initState() {
    super.initState();
    _currentPlot = widget.plot;
    _loadImages();
    _loadComments();
    _loadCurrentUser();
    _loadFavoriteStatus();
    _resolveAddress();
  }

  Future<void> _refreshPlace() async {
    final updatedPlot = await AdminService().getPlaceById(_currentPlot.id);
    if (updatedPlot != null) {
      if (mounted) {
        setState(() {
          _currentPlot = updatedPlot;
          _loadImages();
        });
      }
    }
  }

  void _loadImages() {
    _images.clear();
    if (_currentPlot.images.isNotEmpty) {
      for (var imgPath in _currentPlot.images) {
        _images.add(
          Image.network(
            '${ApiConstants.baseUrl}$imgPath',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
            ),
          ),
        );
      }
    } else if (widget.plot.image.isNotEmpty) {
      _images.add(
        Image.network(
          '${ApiConstants.baseUrl}${widget.plot.image}',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[200],
            child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
          ),
        ),
      );
    } else {
      _images.add(Image.asset('assets/logo/mone.png', fit: BoxFit.cover));
    }
  }

  Future<void> _loadComments() async {
    final comments = await _commentService.getComments(widget.plot.id);
    setState(() {
      _comments = comments;
      _commentsLoading = false;
    });
  }

  Future<void> _loadCurrentUser() async {
    final user = await ProfileService().getuserMe();
    if (user != null) {
      setState(() {
        _currentUser = user;
        _isOwner = user.id == widget.plot.id_user;
      });
    }
  }

  Future<void> _loadFavoriteStatus() async {
    final isFav = await _favoritesService.checkFavorite(widget.plot.id);
    setState(() {
      _isFavorite = isFav;
    });
  }

  Future<void> _toggleFavorite() async {
    final result = await _favoritesService.toggleFavorite(widget.plot.id);
    setState(() {
      _isFavorite = result;
    });
  }

  Future<void> _resolveAddress() async {
    if (widget.plot.coordinates.isEmpty) return;
    try {
      final parts = widget.plot.coordinates.split(',');
      if (parts.length != 2) return;
      final lat = parts[0].trim();
      final lng = parts[1].trim();
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&accept-language=ru',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'SpotfynderApp/1.0'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['display_name'] ?? '';
        if (mounted && address.toString().isNotEmpty) {
          setState(() {
            _resolvedAddress = address.toString();
          });
        }
      }
    } catch (e) {}
  }

  void _showReportDialog() async {
    final types = await _reportService.getReportTypes();
    if (!mounted) return;

    if (types.isEmpty) {
      showFloatingSnackBar(context, 'Не удалось загрузить типы жалоб');
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Пожаловаться',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Выберите причину жалобы',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              ...types.map(
                (type) => InkWell(
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _showReportDescriptionDialog(type.id, type.name);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(type.name, style: TextStyle(fontSize: 16)),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Отмена',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDescriptionDialog(int typeId, String typeName) {
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Описание жалобы',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  typeName,
                  style: TextStyle(
                    color: Colors.red[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Опишите проблему подробнее...',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      'Отмена',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final description = descController.text.trim().isNotEmpty
                          ? descController.text.trim()
                          : typeName;
                      Navigator.pop(dialogContext);
                      final success = await _reportService.sendReport(
                        widget.plot.id,
                        typeId,
                        description,
                      );
                      if (mounted) {
                        showFloatingSnackBar(
                          context,
                          success
                              ? 'Жалоба отправлена'
                              : 'Ошибка отправки жалобы',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Отправить',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  LatLng? _parseCoordinates() {
    if (widget.plot.coordinates.isEmpty) return null;
    try {
      final parts = widget.plot.coordinates.split(',');
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

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes} мин. назад';
      if (diff.inHours < 24) return '${diff.inHours} ч. назад';
      if (diff.inDays < 7) return '${diff.inDays} дн. назад';
      return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return '';
    }
  }

  void _showEditPlace() async {
    final nameController = TextEditingController(text: widget.plot.name);
    final addressController = TextEditingController(text: widget.plot.location);
    final descriptionController = TextEditingController(
      text: widget.plot.description.isNotEmpty
          ? widget.plot.description
          : 'Описания нет',
    );

    final categoriesList = await CategoryService().getCategories();
    final categories = categoriesList.map((c) => c.name).toList();

    String selectedCategory = categories.contains(widget.plot.type)
        ? widget.plot.type
        : (categories.isNotEmpty ? categories.first : 'Стрит-арт');

    List<String> tempOldImages = List.from(widget.plot.images);
    List<XFile> tempNewImages = [];
    final ImagePicker picker = ImagePicker();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
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
                    const SizedBox(height: 20),
                    const Text(
                      'Редактировать место',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Название',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        hintText: 'Название места',
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
                          borderSide: BorderSide(
                            color: AppColors.accentColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Адрес',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: addressController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        hintText: 'Адрес',
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
                          borderSide: BorderSide(
                            color: AppColors.accentColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Категория',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final isSelected = cat == selectedCategory;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedCategory = cat;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: isSelected
                                  ? null
                                  : Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Описание',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        hintText: 'Описание места...',
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
                          borderSide: BorderSide(
                            color: AppColors.accentColor,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: EdgeInsets.all(20),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Фотографии',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...tempOldImages.map((path) {
                            return Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    '${ApiConstants.baseUrl}$path',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          tempOldImages.remove(path);
                                        });
                                      },
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          ...tempNewImages.map((file) {
                            return Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                image: DecorationImage(
                                  image: FileImage(File(file.path)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          tempNewImages.remove(file);
                                        });
                                      },
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          GestureDetector(
                            onTap: () async {
                              final List<XFile> picked = await picker
                                  .pickMultiImage();
                              if (picked.isNotEmpty) {
                                setModalState(() {
                                  tempNewImages.addAll(picked);
                                });
                              }
                            },
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: Colors.grey[400],
                                    size: 30,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Добавить',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final adminServ = AdminService();
                          final categories = await CategoryService()
                              .getCategories();
                          final catId = categories
                              .firstWhere(
                                (c) => c.name == selectedCategory,
                                orElse: () => CategoryModel(id: 1, name: ''),
                              )
                              .id;

                          List<String> finalImagesList = List.from(
                            tempOldImages,
                          );
                          for (var file in tempNewImages) {
                            final bytes = await file.readAsBytes();
                            finalImagesList.add(base64Encode(bytes));
                          }

                          final success = await adminServ.updatePlace(
                            placeId: widget.plot.id,
                            name: nameController.text,
                            description: descriptionController.text,
                            address: addressController.text,
                            idCategory: catId,
                            images: finalImagesList,
                          );

                          if (mounted) {
                            Navigator.pop(context);
                            if (success) {
                              showFloatingSnackBar(
                                context,
                                'Изменения сохранены',
                                duration: const Duration(seconds: 2),
                              );
                              _refreshPlace();
                            } else {
                              showFloatingSnackBar(
                                context,
                                'Ошибка при сохранении',
                                duration: const Duration(seconds: 2),
                              );
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
                        child: Text(
                          'Сохранить изменения',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddComment() {
    _selectedRating = 5;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Добавить комментарий',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Оценка',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              _selectedRating = index + 1;
                            });
                          },
                          child: Icon(
                            index < _selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Ваш комментарий...',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.all(20),
                      ),
                      maxLines: 4,
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Отмена',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (_commentController.text.trim().isEmpty) return;
                            final success = await _commentService.addComment(
                              widget.plot.id,
                              _commentController.text.trim(),
                              _selectedRating,
                            );
                            _commentController.clear();
                            Navigator.pop(context);
                            if (success) {
                              _loadComments();
                              showFloatingSnackBar(
                                context,
                                'Комментарий добавлен',
                              );
                            } else {
                              showFloatingSnackBar(
                                context,
                                'Ошибка отправки. Войдите в аккаунт.',
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Отправить',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) {
                    return Dialog(
                      insetPadding: EdgeInsets.zero,
                      backgroundColor: Colors.black,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PageView.builder(
                            itemCount: _images.length,
                            itemBuilder: (context, index) {
                              return InteractiveViewer(
                                minScale: 1.0,
                                maxScale: 4.0,
                                child: Image(
                                  image: _images[index].image,
                                  fit: BoxFit.contain,
                                ),
                              );
                            },
                          ),
                          Positioned(
                            top: 40,
                            right: 20,
                            child: IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: PageView.builder(
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return Container(
                    foregroundDecoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: _images[index],
                  );
                },
              ),
            ),
          ),

          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.8),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => context.router.maybePop(),
              ),
            ),
          ),

          if (_currentUser != null)
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.8),
                child: IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.black,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ),
            ),

          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.plot.name,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  height: 1.1,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _resolvedAddress.isNotEmpty
                                          ? _resolvedAddress
                                          : (_currentPlot.location.isNotEmpty
                                                ? _currentPlot.location
                                                : (_currentPlot
                                                          .coordinates
                                                          .isNotEmpty
                                                      ? _currentPlot.coordinates
                                                      : 'Без адреса')),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_isOwner)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue[300]),
                              onPressed: () {
                                _showEditPlace();
                              },
                            ),
                          ),
                        if (_isOwner) SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.flag_outlined,
                              color: Colors.red[300],
                            ),
                            onPressed: () {
                              if (_currentUser == null) {
                                showFloatingSnackBar(
                                  context,
                                  'Войдите, чтобы пожаловаться',
                                );
                                return;
                              }
                              _showReportDialog();
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              (_currentPlot.authorAvatar != null &&
                                  _currentPlot.authorAvatar!.isNotEmpty)
                              ? NetworkImage(
                                  '${ApiConstants.baseUrl}${_currentPlot.authorAvatar}',
                                )
                              : null,
                          child:
                              (_currentPlot.authorAvatar == null ||
                                  _currentPlot.authorAvatar!.isEmpty)
                              ? Icon(Icons.person, color: Colors.grey[400])
                              : null,
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentPlot.authorName.isNotEmpty
                                  ? _currentPlot.authorName
                                  : 'Неизвестный автор',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 25),

                    Text(
                      'Описание',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _currentPlot.description.isNotEmpty
                          ? _currentPlot.description
                          : 'Без описания',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          final coords = _parseCoordinates();
                          if (coords == null) {
                            showFloatingSnackBar(
                              context,
                              'Координаты места не указаны',
                            );
                            return;
                          }
                          MapFocusState().setFocus(
                            _currentPlot.coordinates,
                            _currentPlot.name,
                          );
                          context.router.popUntilRoot();
                          context.router.navigate(
                            MapRoute(
                              focusCoordinates: _currentPlot.coordinates,
                              focusName: _currentPlot.name,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Показать на карте',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Комментарии (${_comments.length})',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_currentUser != null)
                          TextButton(
                            onPressed: _showAddComment,
                            child: Text(
                              'Написать',
                              style: TextStyle(
                                color: AppColors.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 15),

                    if (_commentsLoading)
                      Center(child: CircularProgressIndicator())
                    else if (_comments.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Пока нет комментариев',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _comments.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 15,
                                      backgroundColor: Colors.grey[300],
                                      backgroundImage:
                                          (comment.authorAvatar != null &&
                                              comment.authorAvatar!.isNotEmpty)
                                          ? NetworkImage(
                                              '${ApiConstants.baseUrl}${comment.authorAvatar}',
                                            )
                                          : null,
                                      child:
                                          (comment.authorAvatar == null ||
                                              comment.authorAvatar!.isEmpty)
                                          ? Icon(
                                              Icons.person,
                                              size: 18,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        comment.authorName.isNotEmpty
                                            ? comment.authorName
                                            : 'Пользователь',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(5, (i) {
                                        return Icon(
                                          i < comment.estimation
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 14,
                                        );
                                      }),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      _formatDate(comment.createdAt),
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (_currentUser != null && (_currentUser!.id == comment.idUser || _currentUser!.id_role == 2)) ...[
                                      Spacer(),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, size: 20, color: Colors.red[400]),
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                        onPressed: () async {
                                          bool confirm = await showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: Text('Удаление'),
                                              content: Text('Вы уверены, что хотите удалить комментарий?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Отмена')),
                                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Удалить', style: TextStyle(color: Colors.red))),
                                              ]
                                            )
                                          ) ?? false;
                                          if (!confirm) return;

                                          final success = _currentUser!.id_role == 2
                                              ? await _commentService.deleteCommentAdmin(comment.id)
                                              : await _commentService.deleteComment(comment.id);
                                          if (success) {
                                            _loadComments();
                                          } else {
                                            if (!mounted) return;
                                            showFloatingSnackBar(
                                              context,
                                              'Не удалось удалить комментарий',
                                            );
                                          }
                                        },
                                      ),
                                    ]
                                  ],
                                ),
                                SizedBox(height: 10),
                                Text(
                                  comment.comment,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

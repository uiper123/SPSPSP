import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:spt/core/constant/colors.dart';
import 'package:spt/core/constant/api_constants.dart';
import 'package:spt/models/route_model.dart';
import 'package:spt/models/user_model.dart';
import 'package:spt/serv/route_serv.dart';
import 'package:spt/serv/profile_serv.dart';
import 'package:spt/routing/app_router.dart';
import 'package:spt/models/plots_model.dart';
import 'package:spt/widgets/route_editor_sheet.dart';
import 'package:spt/core/map_focus.dart';
import 'package:spt/core/utils/snackbar_helper.dart';

@RoutePage()
class DetailRoutePage extends StatefulWidget {
  final RouteModel route;

  const DetailRoutePage({super.key, required this.route});

  @override
  State<DetailRoutePage> createState() => _DetailRoutePageState();
}

class _DetailRoutePageState extends State<DetailRoutePage> {
  final RouteService _routeService = RouteService();
  final ProfileService _profileService = ProfileService();

  List<RouteCommentModel> _comments = [];
  bool _commentsLoading = true;
  bool _isFavorite = false;
  UserModel? _currentUser;
  late RouteModel _route;

  int _selectedStars = 5;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _route = widget.route;
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = await _profileService.getuserMe();
    if (mounted) setState(() => _currentUser = user);

    final comments = await _routeService.getComments(_route.id);
    if (mounted) {
      setState(() {
        _comments = comments;
        _commentsLoading = false;
      });
    }

    if (user != null) {
      final isFav = await _routeService.checkFavorite(_route.id);
      if (mounted) setState(() => _isFavorite = isFav);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentUser == null) {
      showFloatingSnackBar(
        context,
        'Войдите, чтобы добавить в избранное',
      );
      return;
    }
    final result = await _routeService.toggleFavorite(_route.id);
    setState(() => _isFavorite = result);
  }

  void _showEditRoute() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => RouteEditorSheet(
        route: _route,
        onSaved: (updatedRoute) {
          setState(() => _route = updatedRoute);
        },
      ),
    );
  }

  Future<void> _deleteRoute() async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Удалить маршрут?'),
            content: const Text('Это действие нельзя отменить.'),
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
    final success = await _routeService.deleteRoute(_route.id);
    if (success && mounted) Navigator.of(context).pop(true);
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  void _startTrackingRoute() {
    final routeCoordinates = _route.places
        .map((place) => place.coordinates.trim())
        .where((coordinates) => coordinates.isNotEmpty)
        .toList();

    if (routeCoordinates.length < 2) {
      showFloatingSnackBar(
        context,
        'Для отслеживания нужны хотя бы 2 точки маршрута',
      );
      return;
    }

    final mapFocusState = MapFocusState();
    mapFocusState.clear();
    mapFocusState.setRouteFocus(_route.id, routeCoordinates, _route.name);

    context.router.popUntilRoot();
    context.router.navigate(MapRoute());
  }

  void _showAddComment() {
    _selectedStars = 5;
    showDialog(
      context: context,
      builder: (dialogContext) {
        var isSending = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Добавить комментарий',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Оценка',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              _selectedStars = index + 1;
                            });
                          },
                          child: Icon(
                            index < _selectedStars
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
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
                        contentPadding: const EdgeInsets.all(20),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: isSending
                              ? null
                              : () => Navigator.pop(dialogContext),
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
                          onPressed: isSending
                              ? null
                              : () async {
                                  final text = _commentController.text.trim();
                                  if (text.isEmpty) return;
                                  final navigator = Navigator.of(dialogContext);
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  setDialogState(() => isSending = true);
                                  final success = await _routeService
                                      .addComment(
                                        _route.id,
                                        text,
                                        _selectedStars,
                                      );
                                  if (!mounted) return;
                                  if (success) {
                                    _commentController.clear();
                                    navigator.pop();
                                    final fresh = await _routeService
                                        .getComments(_route.id);
                                    if (mounted) {
                                      setState(() => _comments = fresh);
                                    }
                                  } else {
                                    setDialogState(() => isSending = false);
                                    showFloatingSnackBar(
                                      context,
                                      'Не удалось отправить комментарий (подождите 1 минуту)',
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            elevation: 0,
                          ),
                          child: isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
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
    final route = _route;
    final isOwnerOrAdmin =
        _currentUser != null &&
        (_currentUser!.id == route.idUser || _currentUser!.id_role == 2);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.colordark,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red[300] : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
              if (isOwnerOrAdmin)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: _showEditRoute,
                ),
              if (isOwnerOrAdmin)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: _deleteRoute,
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(60, 0, 60, 14),
              title: Text(
                route.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.mainGradient,
                ),
                child: Center(
                  child: Icon(
                    Icons.route_rounded,
                    size: 72,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            (route.authorAvatar != null &&
                                route.authorAvatar!.isNotEmpty)
                            ? NetworkImage(
                                    '${ApiConstants.baseUrl}${route.authorAvatar}',
                                  )
                                  as ImageProvider
                            : null,
                        child:
                            (route.authorAvatar == null ||
                                route.authorAvatar!.isEmpty)
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              route.authorName.isNotEmpty
                                  ? route.authorName
                                  : 'Пользователь',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 13,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  route.averageRating > 0
                                      ? route.averageRating.toStringAsFixed(1)
                                      : 'Нет оценок',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${route.places.length} мест',
                          style: const TextStyle(
                            color: AppColors.accentColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (route.description != null &&
                      route.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      route.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _startTrackingRoute,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.route, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Отслеживать маршрут',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Точки маршрута',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...route.places.asMap().entries.map((entry) {
                    final index = entry.key;
                    final place = entry.value;
                    final isLast = index == route.places.length - 1;
                    return _buildPlaceStep(place, index, isLast);
                  }),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Комментарии (${_comments.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_currentUser != null)
                        TextButton(
                          onPressed: _showAddComment,
                          child: const Text(
                            'Написать',
                            style: TextStyle(
                              color: AppColors.accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_commentsLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_comments.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Пока нет комментариев',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 15,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) =>
                          _buildCommentCard(_comments[index]),
                    ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceStep(RoutePlaceItem place, int index, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == 0
                      ? const Color(0xFF00B48F)
                      : isLast
                      ? const Color(0xFFE53935)
                      : AppColors.accentColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: index == 0
                      ? const Icon(
                          Icons.flag_rounded,
                          color: Colors.white,
                          size: 15,
                        )
                      : isLast
                      ? const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 15,
                        )
                      : Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: () {
                final plotsModel = PlotsModel(
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
                context.router.push(DetailPlaceRoute(plot: plotsModel));
              },
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: place.image.isNotEmpty
                          ? Image.network(
                              '${ApiConstants.baseUrl}${place.image}',
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imagePlaceholder(),
                            )
                          : _imagePlaceholder(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (place.location.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 12,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    place.location,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.grey[200],
      child: Icon(Icons.image, color: Colors.grey[400], size: 24),
    );
  }

  Widget _buildCommentCard(RouteCommentModel comment) {
    final canDelete =
        _currentUser != null &&
        (_currentUser!.id == comment.idUser || _currentUser!.id_role == 2);

    return Container(
      padding: const EdgeInsets.all(15),
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
                          as ImageProvider
                    : null,
                child:
                    (comment.authorAvatar == null ||
                        comment.authorAvatar!.isEmpty)
                    ? const Icon(Icons.person, size: 18, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  comment.authorName.isNotEmpty
                      ? comment.authorName
                      : 'Пользователь',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < comment.estimation ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(comment.createdAt),
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (canDelete) ...[
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red[400],
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    final ok = await _routeService.deleteComment(comment.id);
                    if (ok) {
                      final fresh = await _routeService.getComments(_route.id);
                      if (mounted) setState(() => _comments = fresh);
                    }
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment.comment,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:spt/core/constant/colors.dart';
import 'package:spt/core/constant/api_constants.dart';
import 'package:spt/core/utils/snackbar_helper.dart';
import 'package:auto_route/auto_route.dart';
import 'package:spt/serv/category_serv.dart';
import 'package:spt/models/plots_model.dart';
import 'package:spt/serv/searchPlots_serv.dart';
import 'package:spt/serv/favorites_serv.dart';
import 'package:spt/core/auth/token_storage.dart';
import 'package:spt/widgets/address_text.dart';

import 'package:spt/routing/app_router.dart';

@RoutePage()
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  double _rating = 5;
  double _minDistance = 500;
  final double _maxDistance = 500;
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  Position? _currentPosition;

  String _selectedCategory = 'Все';
  final Set<int> _favoritePlaceIds = {};

  List<PlotsModel> _plots = [];
  List<CategoryModel> _categoriesList = [];
  bool _isLoading = true;
  bool _isLoggedIn = false;
  int _displayedItemCount = 10;
  final SearchPlots _searchService = SearchPlots();
  final CategoryService _categoryService = CategoryService();
  final FavoritesService _favoritesService = FavoritesService();

  TabsRouter? _tabsRouter;

  @override
  void initState() {
    super.initState();
    _rating = 5;
    _minDistance = 500;
    _selectedCountry = null;
    _selectedState = null;
    _selectedCity = null;
    _selectedCategory = 'Все';

    _fetchCategories();
    _getCurrentLocation().then((_) => _fetchPlots());
    _checkAuth();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _checkAuth() async {
    final token = await tokenStorage.readToken();
    setState(() {
      _isLoggedIn = token != null;
    });
    if (_isLoggedIn) {
      _loadFavoriteIds();
    }
  }

  Future<void> _loadFavoriteIds() async {
    final favPlaces = await _favoritesService.getMyFavorites();
    setState(() {
      _favoritePlaceIds.clear();
      for (var p in favPlaces) {
        _favoritePlaceIds.add(p.id);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final newTabsRouter = AutoTabsRouter.of(context);
      if (_tabsRouter != newTabsRouter) {
        _tabsRouter?.removeListener(_onTabChanged);
        _tabsRouter = newTabsRouter;
        _tabsRouter?.addListener(_onTabChanged);
      }
    } catch (e) {}
  }

  void _onTabChanged() {
    if (_tabsRouter != null && _tabsRouter!.activeIndex != 1) {
      if (_selectedCategory != 'Все' ||
          _rating != 5 ||
          _selectedCountry != null ||
          _selectedState != null ||
          _selectedCity != null) {
        if (mounted) {
          setState(() {
            _rating = 5;
            _minDistance = 500;
            _selectedCountry = null;
            _selectedState = null;
            _selectedCity = null;
            _selectedCategory = 'Все';
          });
          _fetchPlots();
        }
      }
    }
  }

  Future<void> _fetchCategories() async {
    final fetchedCategories = await _categoryService.getCategories();
    setState(() {
      _categoriesList = fetchedCategories;
    });
  }

  Future<void> _fetchPlots() async {
    setState(() {
      _isLoading = true;
      _displayedItemCount = 10;
    });

    int? categoryId;
    if (_selectedCategory != 'Все') {
      for (var category in _categoriesList) {
        if (category.name == _selectedCategory) {
          categoryId = category.id;
          break;
        }
      }
    }

    final plots = await _searchService.searchPlots(
      idCategory: categoryId,
      rating: _rating < 5 ? _rating.toInt() : null,
      country: _selectedCountry,
      region: _selectedState,
      city: _selectedCity,
      name: _searchController.text,
      distance: _minDistance == 500 ? null : _minDistance,
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
    );

    setState(() {
      _plots = plots;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _tabsRouter?.removeListener(_onTabChanged);
    super.dispose();
  }

  Widget _buildArtworks(int index, PlotsModel plot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            context.router.push(DetailPlaceRoute(plot: plot));
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: plot.image.isNotEmpty
                      ? Image.network(
                          '${ApiConstants.baseUrl}${plot.image}',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey[400],
                                  size: 30,
                                ),
                              ),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image,
                            color: Colors.grey[400],
                            size: 30,
                          ),
                        ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plot.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            plot.type.isNotEmpty ? plot.type : 'Без категории',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              plot.authorName.isNotEmpty
                                  ? plot.authorName
                                  : 'Неизвестный автор',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: AddressText(
                              initialLocation: plot.location,
                              coordinates: plot.coordinates,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            plot.averageRating > 0
                                ? plot.averageRating.toString()
                                : 'Нет оценок',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _favoritePlaceIds.contains(plot.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _favoritePlaceIds.contains(plot.id)
                        ? Colors.red
                        : Colors.grey[400],
                    size: 22,
                  ),
                  onPressed: () async {
                    if (!_isLoggedIn) {
                      showFloatingSnackBar(
                        context,
                        'Войдите, чтобы добавить в избранное',
                      );
                      return;
                    }
                    final result = await _favoritesService.toggleFavorite(
                      plot.id,
                    );
                    setState(() {
                      if (result) {
                        _favoritePlaceIds.add(plot.id);
                      } else {
                        _favoritePlaceIds.remove(plot.id);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryChips([StateSetter? modalState]) {
    List<String> cats = [];
    cats.add('Все');
    for (var categoryItem in _categoriesList) {
      cats.add(categoryItem.name);
    }

    return cats.map((category) {
      return GestureDetector(
        onTap: () {
          final stateUse = modalState ?? setState;
          stateUse(() {
            _selectedCategory = category;
          });
          if (modalState == null) _fetchPlots();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: _selectedCategory == category
                ? AppColors.accentColor
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: _selectedCategory == category
                ? null
                : Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            category,
            style: TextStyle(
              color: _selectedCategory == category
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ),
      );
    }).toList();
  }

  Set<String> _getCountrySuggestions() {
    final suggestions = <String>{
      'Россия',
      'Беларусь',
      'Казахстан',
      'Армения',
      'Грузия',
      'Кыргызстан',
      'Узбекистан',
    };
    for (var plot in _plots) {
      if (plot.location.isNotEmpty) {
        final parts = plot.location.split(',');
        if (parts.isNotEmpty) {
          final country = parts[0].trim();
          if (country.isNotEmpty && country.length < 35) {
            suggestions.add(country);
          }
        }
        if (parts.length > 1) {
          final region = parts[1].trim();
          if (region.isNotEmpty && region.length < 40 && !region.contains(RegExp(r'\d'))) {
            suggestions.add(region);
          }
        }
      }
    }
    return suggestions;
  }

  Set<String> _getCitySuggestions() {
    final suggestions = <String>{
      'Москва',
      'Санкт-Петербург',
      'Новокузнецк',
      'Кемерово',
      'Новосибирск',
      'Екатеринбург',
      'Казань',
      'Нижний Новгород',
      'Челябинск',
      'Самара',
      'Омск',
      'Ростов-на-Дону',
      'Уфа',
      'Красноярск',
      'Пермь',
      'Воронеж',
      'Волгоград',
    };
    for (var plot in _plots) {
      if (plot.location.isNotEmpty) {
        final parts = plot.location.split(',');
        if (parts.length > 2) {
          final city = parts[2].trim();
          if (city.isNotEmpty && city.length < 35 && !city.contains(RegExp(r'\d'))) {
            suggestions.add(city);
          }
        } else if (parts.length > 1) {
          final city = parts[1].trim();
          if (city.isNotEmpty && city.length < 35 && !city.contains(RegExp(r'\d'))) {
            suggestions.add(city);
          }
        }
      }
    }
    return suggestions;
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required VoidCallback onFieldSubmitted,
    required String hintText,
    required IconData prefixIcon,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: AppColors.accentColor),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onSubmitted: (_) => onFieldSubmitted(),
      onChanged: onChanged,
    );
  }

  Widget _buildAutocompleteOptions(
    BuildContext context,
    AutocompleteOnSelected<String> onSelected,
    Iterable<String> options,
  ) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: MediaQuery.of(context).size.width - 40,
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (BuildContext context, int index) {
              final String option = options.elementAt(index);
              return InkWell(
                onTap: () => onSelected(option),
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(12) : Radius.zero,
                  bottom: index == options.length - 1 ? const Radius.circular(12) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        option,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showFilterModal() {
    _cityController.text = _selectedCity ?? '';
    _countryController.text = _selectedCountry ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return _buildFilterModal(setModalState, scrollController);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFilterModal(
    StateSetter setModalState,
    ScrollController scrollController,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
          'Фильтры',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        const Text(
          'Местоположение',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return _getCountrySuggestions().where((String option) {
              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            setModalState(() {
              _selectedCountry = selection;
              _countryController.text = selection;
            });
            setState(() {
              _selectedCountry = selection;
              _countryController.text = selection;
            });
          },
          optionsViewBuilder: (context, onSelected, options) {
            return _buildAutocompleteOptions(context, onSelected, options);
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            if (textEditingController.text != _countryController.text) {
              textEditingController.text = _countryController.text;
            }
            return _buildAutocompleteField(
              controller: textEditingController,
              focusNode: focusNode,
              onFieldSubmitted: onFieldSubmitted,
              hintText: 'Страна или регион',
              prefixIcon: Icons.map_outlined,
              onChanged: (value) {
                _countryController.text = value;
                setModalState(() {
                  _selectedCountry = value.trim().isEmpty ? null : value.trim();
                });
                setState(() {
                  _selectedCountry = value.trim().isEmpty ? null : value.trim();
                });
              },
            );
          },
        ),
        const SizedBox(height: 12),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return _getCitySuggestions().where((String option) {
              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            setModalState(() {
              _selectedCity = selection;
              _cityController.text = selection;
            });
            setState(() {
              _selectedCity = selection;
              _cityController.text = selection;
            });
          },
          optionsViewBuilder: (context, onSelected, options) {
            return _buildAutocompleteOptions(context, onSelected, options);
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            if (textEditingController.text != _cityController.text) {
              textEditingController.text = _cityController.text;
            }
            return _buildAutocompleteField(
              controller: textEditingController,
              focusNode: focusNode,
              onFieldSubmitted: onFieldSubmitted,
              hintText: 'Город',
              prefixIcon: Icons.location_city_outlined,
              onChanged: (value) {
                _cityController.text = value;
                setModalState(() {
                  _selectedCity = value.trim().isEmpty ? null : value.trim();
                });
                setState(() {
                  _selectedCity = value.trim().isEmpty ? null : value.trim();
                });
              },
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Категория',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.start,
          spacing: 8.0,
          runSpacing: 8.0,
          children: _buildCategoryChips(setModalState),
        ),
        const SizedBox(height: 24),
        const Text(
          'Расстояние',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _minDistance,
          min: 0,
          max: 500,
          divisions: 500,
          activeColor: AppColors.accentColor,
          label: '${_minDistance.round()} км',
          onChanged: (value) {
            setModalState(() {
              _minDistance = value;
            });
            setState(() {
              _minDistance = value;
            });
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Рейтинг',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(5, (index) {
            final starRating = index + 1;
            final isSelected = starRating <= _rating;
            return GestureDetector(
              onTap: () {
                setModalState(() {
                  _rating = starRating.toDouble();
                });
                setState(() {
                  _rating = starRating.toDouble();
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isSelected ? Colors.amber[600] : Colors.grey[300],
                  size: 32,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _cityController.clear();
                    _countryController.clear();
                    setModalState(() {
                      _rating = 5;
                      _minDistance = 500;
                      _selectedCountry = null;
                      _selectedState = null;
                      _selectedCity = null;
                      _selectedCategory = 'Все';
                    });
                    setState(() {
                      _rating = 5;
                      _minDistance = 500;
                      _selectedCountry = null;
                      _selectedState = null;
                      _selectedCity = null;
                      _selectedCategory = 'Все';
                    });
                    _fetchPlots();
                    showFloatingSnackBar(
                      context,
                      'Фильтры сброшены',
                      duration: const Duration(seconds: 2),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Сбросить',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _fetchPlots();
                    showFloatingSnackBar(
                      context,
                      'Фильтры применены',
                      duration: const Duration(seconds: 2),
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
                  child: const Text(
                    'Применить',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text(
              'Поиск',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => _fetchPlots(),
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  hintText: 'Поиск',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _showFilterModal();
                    },
                    icon: Icon(Icons.filter_list),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: _buildCategoryChips()),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _plots.isEmpty
                    ? const Center(
                        child: Text(
                          'Ничего не найдено',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchPlots,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _plots.length > _displayedItemCount
                              ? _displayedItemCount + 1
                              : _plots.length,
                          itemBuilder: (context, index) {
                            if (index == _displayedItemCount) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: 20,
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _displayedItemCount += 10;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                  ),
                                  child: const Text(
                                    'Показать еще',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return _buildArtworks(index, _plots[index]);
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

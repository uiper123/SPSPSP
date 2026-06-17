import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:spt/routing/app_router.dart';
import 'package:spt/core/constant/colors.dart';
import 'package:spt/core/utils/snackbar_helper.dart';
import 'package:spt/core/auth/token_storage.dart';

@RoutePage()
class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await tokenStorage.readToken();
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AutoTabsScaffold(
      routes: [
        MapRoute(),
        SearchRoute(),
        AddPlaceRoute(),
        RewidRoute(),
        ProfileRoute(),
        RoutesRoute(),
      ],
      extendBody: true,
      navigatorObservers: () => [],
      bottomNavigationBuilder: (context, tabsRouter) {
        return _FloatingNavBar(
          tabsRouter: tabsRouter,
          isLoggedIn: _isLoggedIn,
          onCheckAuth: _checkAuth,
        );
      },
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final TabsRouter tabsRouter;
  final bool isLoggedIn;
  final VoidCallback onCheckAuth;

  const _FloatingNavBar({
    required this.tabsRouter,
    required this.isLoggedIn,
    required this.onCheckAuth,
  });

  static const double _barHeight = 62;
  static const double _fabSize = 56;
  static const double _notchMargin = 6;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
      child: SizedBox(
        height: _barHeight + _fabSize / 2 + _notchMargin,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Bar with notch
            CustomPaint(
              size: Size(double.infinity, _barHeight),
              painter: _NotchedBarPainter(
                notchRadius: _fabSize / 2 + _notchMargin,
                cornerRadius: 32,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.colorlight.withOpacity(0.88),
                    AppColors.colordark.withOpacity(0.92),
                  ],
                ),
                borderColor: Colors.white.withOpacity(0.15),
                shadowColor: AppColors.colordark.withOpacity(0.5),
              ),
              child: SizedBox(
                height: _barHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(
                            icon: Icons.map_outlined,
                            activeIcon: Icons.map_rounded,
                            index: 0,
                          ),
                          _buildNavItem(
                            icon: Icons.search_rounded,
                            activeIcon: Icons.search_rounded,
                            index: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 72),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(
                            icon: Icons.star_border_rounded,
                            activeIcon: Icons.star_rounded,
                            index: 3,
                          ),
                          _buildNavItem(
                            icon: Icons.route_outlined,
                            activeIcon: Icons.route_rounded,
                            index: 5,
                          ),
                          _buildNavItem(
                            icon: Icons.person_outline_rounded,
                            activeIcon: Icons.person_rounded,
                            index: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // FAB button
            Positioned(top: 0, child: _buildCenterButton(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
  }) {
    final isSelected = tabsRouter.activeIndex == index;
    return GestureDetector(
      onTap: () {
        tabsRouter.setActiveIndex(index);
        onCheckAuth();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              isSelected ? activeIcon : icon,
              key: ValueKey('$index-$isSelected'),
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.45),
              size: isSelected ? 26 : 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton(BuildContext context) {
    final isActive = tabsRouter.activeIndex == 2;
    return GestureDetector(
      onTap: isLoggedIn
          ? () => tabsRouter.setActiveIndex(2)
          : () {
              showFloatingSnackBar(
                context,
                'Войдите, чтобы добавить место',
              );
            },
      child: Container(
        width: _fabSize,
        height: _fabSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLoggedIn
                ? [AppColors.colorlight, AppColors.accentColor]
                : [Colors.grey[500]!, Colors.grey[600]!],
          ),
          boxShadow: [
            BoxShadow(
              color: (isLoggedIn ? AppColors.accentColor : Colors.grey)
                  .withOpacity(0.45),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
            if (isActive)
              BoxShadow(
                color: AppColors.colorlight.withOpacity(0.35),
                blurRadius: 18,
                spreadRadius: 2,
              ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}

class _NotchedBarPainter extends CustomPainter {
  final double notchRadius;
  final double cornerRadius;
  final LinearGradient gradient;
  final Color borderColor;
  final Color shadowColor;

  _NotchedBarPainter({
    required this.notchRadius,
    required this.cornerRadius,
    required this.gradient,
    required this.borderColor,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildNotchedPath(size);

    // Shadow
    canvas.drawShadow(path, shadowColor, 16, true);

    // Fill with gradient
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    canvas.drawPath(path, paint);

    // Border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, borderPaint);
  }

  Path _buildNotchedPath(Size size) {
    final midX = size.width / 2;
    final notchStartX = midX - notchRadius - 8;
    final notchEndX = midX + notchRadius + 8;

    final path = Path();

    // Start at top-left corner
    path.moveTo(cornerRadius, 0);

    // Top edge to notch
    path.lineTo(notchStartX, 0);

    // Notch curve (smooth quadratic bezier)
    path.quadraticBezierTo(
      midX - notchRadius + 4,
      0,
      midX - notchRadius + 6,
      notchRadius * 0.35,
    );
    path.arcToPoint(
      Offset(midX + notchRadius - 6, notchRadius * 0.35),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.quadraticBezierTo(midX + notchRadius - 4, 0, notchEndX, 0);

    // Top edge after notch to top-right corner
    path.lineTo(size.width - cornerRadius, 0);

    // Top-right corner
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

    // Right edge
    path.lineTo(size.width, size.height - cornerRadius);

    // Bottom-right corner
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - cornerRadius,
      size.height,
    );

    // Bottom edge
    path.lineTo(cornerRadius, size.height);

    // Bottom-left corner
    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

    // Left edge
    path.lineTo(0, cornerRadius);

    // Top-left corner
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _NotchedBarPainter oldDelegate) =>
      notchRadius != oldDelegate.notchRadius ||
      cornerRadius != oldDelegate.cornerRadius;
}

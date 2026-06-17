import 'package:flutter/material.dart';
import 'package:spt/core/constant/colors.dart';
import 'package:auto_route/auto_route.dart';
import 'package:spt/routing/app_router.dart';
import 'package:spt/serv/auth_serv.dart';
import 'package:spt/serv/profile_serv.dart';

@RoutePage()
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _isCheckingAuth = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _checkAuthAndNavigate() async {
    setState(() {
      _isCheckingAuth = true;
    });

    try {
      final user = await ProfileService().getuserMe();

      if (mounted) {
        if (user != null) {
          context.router.replace(const MainRoute());
        } else {
          context.router.replace(LoginRoute());
        }
      }
    } catch (e) {
      if (mounted) {
        context.router.replace(LoginRoute());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: Stack(
          children: [
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 100),

                  Image.asset(
                    'assets/logo/splash_logo.png',
                    width: 220,
                    height: 220,
                    fit: BoxFit.contain,

                    errorBuilder: (context, error, StackTrace) =>
                        const Icon(Icons.image, size: 100),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'Spotfynder',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipPath(
                clipper: _BottomShapeClipper(),
                child: Container(
                  color: const Color.fromARGB(255, 214, 209, 209),
                  height: 300,
                  width: double.infinity,
                  child: _isCheckingAuth
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentColor,
                          ),
                        )
                      : Column(
                          children: [
                            const SizedBox(height: 160),
                            const Text(
                              'Готовы исследовать?',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: _checkAuthAndNavigate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                fixedSize: const Size(270, 50),
                              ),
                              child: const Text('Начать'),
                            ),
                          ],
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

class _BottomShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.6);
    path.lineTo(size.width, size.height * 0.1);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

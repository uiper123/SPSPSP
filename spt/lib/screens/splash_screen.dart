import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:spt/core/constant/colors.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:auto_route/auto_route.dart';
import 'package:spt/routing/app_router.dart';
import 'dart:io';

@RoutePage()
class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreen();
}

class _SplashScreen extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkInternet();
    fetchdate();
  }

  Future<void> checkInternet() async {
    await Future.delayed(const Duration(seconds: 2));
    try {
      if (kIsWeb) {
        if (mounted) {
          context.router.replace(WelcomeRoute());
        }
      }
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('Интернет работает');
        if (mounted) {
          context.router.replace(WelcomeRoute());
        }
      }
    } on SocketException catch (_) {
      print('Интернет не работает');
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.wifi_off,
                      color: Colors.red[400],
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Ошибка сети',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Для работы приложения требуется интернет соединение.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.router.replace(SplashRoute());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Попробовать снова'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> fetchdate() async {
    await Future.delayed(const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Исследуйте уличное искусство и достопримечательности вместе со SpotFynder.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),

            const SizedBox(height: 100),

            LoadingAnimationWidget.flickr(
              leftDotColor: const Color.fromARGB(255, 240, 240, 240),
              rightDotColor: const Color.fromARGB(255, 126, 125, 125),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

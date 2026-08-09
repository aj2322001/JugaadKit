import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 28,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.22;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        AppConstants.appIconAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          return _AppLogoFallback(size: size, radius: radius);
        },
      ),
    );
  }
}

class _AppLogoFallback extends StatelessWidget {
  const _AppLogoFallback({
    required this.size,
    required this.radius,
  });

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        'J',
        style: TextStyle(
          color: const Color(0xFF38BDF8),
          fontSize: size * 0.58,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

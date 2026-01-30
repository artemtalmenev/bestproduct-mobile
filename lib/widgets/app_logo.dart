import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Логотип приложения (SVG).
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 48,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        'assets/logo.svg',
        fit: BoxFit.contain,
      ),
    );
  }
}

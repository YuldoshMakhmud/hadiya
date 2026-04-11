import 'package:flutter/material.dart';
import '../app_theme.dart';

class HadiyaLogo extends StatelessWidget {
  final double size;
  final bool darkBackground;

  const HadiyaLogo({super.key, this.size = 80, this.darkBackground = true});

  @override
  Widget build(BuildContext context) {
    final color = darkBackground ? AppColors.cream : AppColors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'H',
              style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w900,
                color: color,
                fontFamily: 'serif',
                height: 1,
              ),
            ),
            Positioned(
              top: size * 0.05,
              child: Icon(
                Icons.eco,
                size: size * 0.35,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          'HADIYA',
          style: TextStyle(
            fontSize: size * 0.32,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: size * 0.08,
          ),
        ),
      ],
    );
  }
}

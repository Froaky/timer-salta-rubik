import 'package:flutter/material.dart';

class CategoryIcon extends StatelessWidget {
  final String cubeType;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final EdgeInsetsGeometry backgroundPadding;
  final double backgroundRadius;

  const CategoryIcon({
    super.key,
    required this.cubeType,
    this.size = 18,
    this.color,
    this.backgroundColor,
    this.backgroundPadding = EdgeInsets.zero,
    this.backgroundRadius = 0,
  });

  static const Map<String, String> _assetByCubeType = {
    '2x2': '222.png',
    '3x3': '333.png',
    '3x3oh': '333oh.png',
    '3x3bf': '333bf.png',
    '3x3fm': '333fm.png',
    '3x3mbf': '333mbf.png',
    '4x4': '444.png',
    '444bf': '444bf.png',
    '4x4bf': '444bf.png',
    '5x5': '555.png',
    '555bf': '555bf.png',
    '5x5bf': '555bf.png',
    '6x6': '666.png',
    '7x7': '777.png',
    'pyraminx': 'pyram.png',
    'megaminx': 'minx.png',
    'skewb': 'skewb.png',
    'clock': 'clock.png',
    'sq1': 'sq1.png',
    'square-1': 'sq1.png',
  };

  @override
  Widget build(BuildContext context) {
    final normalizedType = cubeType.toLowerCase();
    final assetName = _assetByCubeType[normalizedType] ?? '333.png';

    final icon = Image.asset(
      'assets/icons/categories/$assetName',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.help_outline,
          size: size,
          color: color,
        );
      },
    );

    if (backgroundColor == null) {
      return icon;
    }

    return Container(
      padding: backgroundPadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(backgroundRadius),
      ),
      child: icon,
    );
  }
}

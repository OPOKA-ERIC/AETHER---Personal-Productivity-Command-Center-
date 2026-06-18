import 'package:flutter/material.dart';
import '../theme/aether_theme.dart';

class CategoryBadge extends StatelessWidget {
  final String category;
  final double size;

  const CategoryBadge({
    super.key,
    required this.category,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AetherColors.categoryColor(category),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AetherColors.categoryColor(category).withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class CategoryLabel extends StatelessWidget {
  final String category;

  const CategoryLabel({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final color = AetherColors.categoryColor(category);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CategoryBadge(category: category),
        const SizedBox(width: 8),
        Text(
          category[0].toUpperCase() + category.substring(1),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

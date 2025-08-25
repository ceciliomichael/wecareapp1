import 'package:flutter/material.dart';

class ActivityStatusIndicator extends StatelessWidget {
  final bool isActive;
  final double size;
  final bool showText;

  const ActivityStatusIndicator({
    super.key,
    required this.isActive,
    this.size = 12.0,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.grey;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: size * 1.2,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

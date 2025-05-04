import 'package:flutter/material.dart';

class JobSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAllPressed;
  final Color? textColor;

  const JobSectionHeader({
    Key? key,
    required this.title,
    this.onViewAllPressed,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor ?? Colors.black,
            ),
          ),
          if (onViewAllPressed != null)
            TextButton(
              onPressed: onViewAllPressed,
              child: Text(
                'View All',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}

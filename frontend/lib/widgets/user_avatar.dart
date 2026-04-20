import 'package:flutter/material.dart';
import '../app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String initials;
  final String role;
  final double size;

  const UserAvatar({
    super.key,
    required this.initials,
    required this.role,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.roleColors[role] ?? Colors.grey;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.35,
          )),
      ),
    );
  }
}

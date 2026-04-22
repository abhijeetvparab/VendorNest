import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label,
                  style: const TextStyle(
                    color: Colors.white70, fontSize: 11,
                    fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Icon(icon, color: Colors.white70, size: 22),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
            style: const TextStyle(
              color: Colors.white, fontSize: 22,
              fontWeight: FontWeight.w900),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );

    if (onTap == null) return card;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: card,
      ),
    );
  }
}

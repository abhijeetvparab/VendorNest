import 'package:flutter/material.dart';
import '../app_theme.dart';

class GradientButton extends StatelessWidget {
  final String   label;
  final VoidCallback? onPressed;
  final bool     loading;
  final List<Color> colors;
  final double   width;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.colors  = const [AppTheme.violet, AppTheme.pink],
    this.width   = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors,
            begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
            color: colors.first.withOpacity(0.35),
            blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: loading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(label, style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const purple800 = Color(0xFF6B21A8);
  static const purple700 = Color(0xFF7E22CE);
  static const purple600 = Color(0xFF9333EA);
  static const purple500 = Color(0xFFA855F7);
  static const purple400 = Color(0xFFC084FC);
  static const purple900 = Color(0xFF581C87);
  static const sky600 = Color(0xFF0284C7);
  static const orange600 = Color(0xFFEA580C);
  static const foreground = Color(0xFF4C1D95);
}

class AppTheme {
  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.purple600,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: AppColors.foreground,
        displayColor: AppColors.foreground,
      ),
    );
  }

  static BoxDecoration shellGradient = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF7DD3FC),
        Color(0xFFBAE6FD),
        Color(0xFFFEF08A),
      ],
    ),
  );

  static BoxDecoration loadingGradient = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF87CEEB),
        Color(0xFFFFE066),
      ],
    ),
  );

  static BoxDecoration ctaGradient = const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFFFB923C), Color(0xFFEC4899)],
    ),
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.borderColor = const Color(0xFFBAE6FD),
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color borderColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class CtaButton extends StatelessWidget {
  const CtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: AppTheme.ctaGradient.copyWith(
            color: enabled ? null : Colors.grey,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );

  if (expand) {
      return SizedBox(width: double.infinity, child: child);
    }
    return child;
  }
}

class OutlineButton extends StatelessWidget {
  const OutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.purple600,
        side: const BorderSide(color: Color(0xFFE9D5FF), width: 2),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: child);
    }
    return child;
  }
}

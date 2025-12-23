import 'package:flutter/material.dart';
import 'package:bstock_app/my_flutter_app_icons.dart';

/// Visual style options for the AshReef footer branding.
enum FooterStyle {
  /// Minimal style: "Designed by AshReef Labs [icon]"
  /// Used on Login and Splash screens.
  simple,

  /// Full product style: "[BstocK icon] BstocK by AshReef Labs [icon]"
  /// Used in Sidebar/Drawer.
  fullProduct,
}

/// Reusable footer widget for AshReef Labs branding.
///
/// Supports two visual styles based on context:
/// - [FooterStyle.simple]: Minimal "Designed by" text for splash/login
/// - [FooterStyle.fullProduct]: Full product attribution for sidebar
class AshReefFooter extends StatelessWidget {
  final FooterStyle style;

  const AshReefFooter({
    super.key,
    this.style = FooterStyle.simple,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Monochrome adaptive colors
    final Color primaryColor = isDark
        ? const Color(0xFF9CA3AF) // Lighter grey in dark mode
        : const Color(0xFF6B7280); // Darker grey in light mode

    final Color secondaryColor = isDark
        ? const Color(0xFF6B7280) // Dimmer grey in dark mode
        : const Color(0xFF9CA3AF); // Lighter grey in light mode

    return switch (style) {
      FooterStyle.simple => _buildSimpleFooter(primaryColor),
      FooterStyle.fullProduct => _buildFullProductFooter(
          primaryColor,
          secondaryColor,
        ),
    };
  }

  /// Style 1: Simple "Designed by AshReef Labs" footer
  Widget _buildSimpleFooter(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Designed by ',
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            'AshReef Labs',
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 5),
          Icon(
            AppIcons.ashreef,
            size: 12,
            color: textColor,
          ),
        ],
      ),
    );
  }

  /// Style 2: Full product attribution footer
  /// "[BstocK icon] BstocK by AshReef Labs [icon]"
  Widget _buildFullProductFooter(Color primaryColor, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // BstocK Icon
          Icon(
            AppIcons.bstock,
            size: 17,
            color: primaryColor,
          ),
          const SizedBox(width: 5),
          // BstocK text - Bold, slightly larger
          Text(
            'BstocK',
            style: TextStyle(
              fontSize: 14,
              color: primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          // "by" - Italic, lighter weight, lower opacity
          Text(
            'by',
            style: TextStyle(
              fontSize: 12,
              color: secondaryColor,
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 6),
          // AshReef Labs - Medium weight
          Text(
            'AshReef Labs',
            style: TextStyle(
              fontSize: 12,
              color: primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 5),
          // AshReef Icon
          Icon(
            AppIcons.ashreef,
            size: 14,
            color: primaryColor,
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';

class DecoratedScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const DecoratedScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.drawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = colors.brightness == Brightness.light;
    final screenHeight = MediaQuery.of(context).size.height;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isLight
              ? [
                  colors.surface,
                  colors.background,
                ]
              : [
                  colors.background,
                  colors.surface.withOpacity(0.95),
                ],
        ),
      ),
      child: Stack(
        children: [
          // Large primary smoke wisp - top right
          Positioned(
            top: -100,
            right: -80,
            child: _SmokyBlob(
              color: colors.primary,
              size: 320,
              opacity: isLight ? 0.08 : 0.15,
              blurFactor: 0.7,
            ),
          ),
          // Secondary smoke wisp - bottom left
          Positioned(
            bottom: -120,
            left: -100,
            child: _SmokyBlob(
              color: colors.secondary,
              size: 300,
              opacity: isLight ? 0.1 : 0.18,
              blurFactor: 0.6,
            ),
          ),
          // Smaller primary accent - mid right
          Positioned(
            top: screenHeight * 0.35,
            right: -60,
            child: _SmokyBlob(
              color: colors.primary,
              size: 180,
              opacity: isLight ? 0.06 : 0.12,
              blurFactor: 0.5,
            ),
          ),
          // Subtle secondary wisp - top left
          Positioned(
            top: screenHeight * 0.15,
            left: -70,
            child: _SmokyBlob(
              color: colors.secondary,
              size: 160,
              opacity: isLight ? 0.05 : 0.1,
              blurFactor: 0.8,
            ),
          ),
          // Deep primary accent - bottom right
          Positioned(
            bottom: screenHeight * 0.2,
            right: -40,
            child: _SmokyBlob(
              color: colors.primary,
              size: 140,
              opacity: isLight ? 0.04 : 0.08,
              blurFactor: 0.9,
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: appBar,
            drawer: drawer,
            body: body,
            bottomNavigationBar: bottomNavigationBar,
            floatingActionButton: floatingActionButton,
            floatingActionButtonLocation: floatingActionButtonLocation,
          ),
        ],
      ),
    );
  }
}

/// A smoky blob widget that creates an organic, abstract gradient shape.
class _SmokyBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  final double blurFactor;

  const _SmokyBlob({
    required this.color,
    required this.size,
    this.opacity = 0.1,
    this.blurFactor = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(opacity * 0.6),
            color.withOpacity(opacity * 0.2),
            color.withOpacity(0),
          ],
          stops: [0.0, 0.3 * blurFactor, 0.6 * blurFactor, 1.0],
        ),
      ),
    );
  }
}

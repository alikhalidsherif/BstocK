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

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? [
                  colors.surface,
                  colors.background,
                  colors.primary.withOpacity(0.04),
                ]
              : [
                  colors.background,
                  colors.surface,
                  colors.primary.withOpacity(0.08),
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -60,
            child: _AccentBlob(
              color: colors.primary.withOpacity(isLight ? 0.1 : 0.18),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -80,
            child: _AccentBlob(
              color: colors.tertiary.withOpacity(isLight ? 0.1 : 0.14),
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

class _AccentBlob extends StatelessWidget {
  final Color color;

  const _AccentBlob({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}


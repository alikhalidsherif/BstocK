import 'dart:math';
import 'package:bstock_app/main.dart';
import 'package:bstock_app/providers/auth_provider.dart';
import 'package:bstock_app/widgets/ashreef_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// --- CONFIGURATION ---
const int particleCount = 80;
const double fallSpeed = 3.5;
const Duration splashDuration = Duration(milliseconds: 6500); // 6.5 seconds

/// Animated splash screen with particle sorting animation.
/// Particles fall, get processed through the V, and exit through M legs.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final Random _rng = Random();
  bool _navigating = false;
  bool _isInitialized = false;

  // Particle System
  List<Particle> particles = [];

  // Cached screen dimensions (to avoid MediaQuery issues)
  double _screenWidth = 0;
  double _screenHeight = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _scheduleNavigation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache screen dimensions when they become available
    if (!_isInitialized) {
      final size = MediaQuery.of(context).size;
      if (size.width > 0 && size.height > 0) {
        _screenWidth = size.width;
        _screenHeight = size.height;
        _isInitialized = true;
        _spawnParticles();
      }
    }
  }

  void _scheduleNavigation() {
    Future.delayed(splashDuration, () {
      _navigate();
    });
  }

  void _navigate() {
    if (!mounted || _navigating) return;
    _navigating = true;

    // Mark splash animation as complete to allow router redirect
    AppState.splashAnimationComplete = true;

    final auth = context.read<AuthProvider>();
    final target = auth.status == AuthStatus.authenticated ? '/' : '/login';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go(target);
      }
    });
  }

  void _spawnParticles() async {
    if (_screenWidth <= 0) return;

    for (int i = 0; i < particleCount; i++) {
      // Staggered spawn for rain effect
      await Future.delayed(Duration(milliseconds: _rng.nextInt(80) + 40));
      if (!mounted) return;

      // Randomly choose a Type (0, 1, 2)
      int type = _rng.nextInt(3);

      setState(() {
        particles.add(Particle(
          type: type,
          x: _rng.nextDouble() * _screenWidth,
          y: -40.0 - _rng.nextDouble() * 120, // Start well above screen
          state: ParticleState.falling,
          rotationSpeed: (_rng.nextDouble() - 0.5) * 0.1,
          velocityY: 0.8 + _rng.nextDouble() * 1.2, // Slow initial velocity
        ));
      });
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted || !_isInitialized) return;

    setState(() {
      final centerX = _screenWidth / 2;
      final centerY = _screenHeight / 2;

      // TARGETS - V entry point (inside the V hopper)
      final vEntry = Offset(centerX, centerY - 25);

      // EXIT POINTS (The 3 Legs of the M) - aligned with actual M leg positions
      final exitLeft = Offset(centerX - 30, centerY + 68);
      final exitMid = Offset(centerX, centerY + 65);
      final exitRight = Offset(centerX + 30, centerY + 68);

      for (var p in particles) {
        p.rotation += p.rotationSpeed;

        switch (p.state) {
          case ParticleState.falling:
            // Calculate distance to V entry
            double dx = vEntry.dx - p.x;
            double dy = vEntry.dy - p.y;
            double dist = sqrt(dx * dx + dy * dy);

            // EXPONENTIAL SUCTION - dramatic pull effect
            // Starts gentle, becomes very strong close to the V
            double suctionStrength = 0.0;
            if (dist < 450) {
              // Exponential curve: strength increases dramatically as distance decreases
              double normalizedDist = dist / 450;
              suctionStrength = pow(1 - normalizedDist, 3.0).toDouble() * 0.22;
            }

            // Apply horizontal suction (pulls toward V center)
            p.x += dx * suctionStrength;

            // Natural gravity - slow and floaty
            p.velocityY += 0.06; // Gentle gravity
            p.velocityY = p.velocityY.clamp(0, 6); // Slower max velocity

            // Vertical suction blends with gravity
            double verticalSuction = dy * suctionStrength * 0.5;
            p.y += p.velocityY * 0.45 + verticalSuction;

            // Slow down rotation as particle gets sucked in
            if (dist < 100) {
              p.rotationSpeed *= 0.95;
            }

            // Enter processing when inside the V
            if (dist < 10) {
              p.state = ParticleState.processing;
              p.timer = 0;
              p.x = vEntry.dx;
              p.y = vEntry.dy;
            }
            break;

          case ParticleState.processing:
            // Slow, satisfying shrink into the machine
            p.scale = (1.0 - p.timer * 2.8).clamp(0.0, 1.0);
            p.timer += 0.035;

            // Drift down into the V
            p.y += 1.2;

            // When fully processed, teleport to correct exit
            if (p.timer > 0.9) {
              p.state = ParticleState.sorting;
              p.scale = 0.0;
              p.y = centerY + 30; // Start inside M body

              // Sort to correct leg based on type
              if (p.type == 0) p.x = exitLeft.dx;  // Triangles -> Left
              if (p.type == 1) p.x = exitMid.dx;   // Circles -> Middle
              if (p.type == 2) p.x = exitRight.dx; // Squares -> Right

              p.velocityY = 0;
              p.rotation = 0; // Reset rotation for clean exit
            }
            break;

          case ParticleState.sorting:
            // Smooth pop out and fall
            p.scale = (p.scale + 0.1).clamp(0.0, 1.0);

            // Gentle accelerating fall
            p.velocityY += 0.18;
            p.velocityY = p.velocityY.clamp(0, fallSpeed);
            p.y += p.velocityY;

            // Organize into neat columns
            double targetColumnX = 0;
            if (p.type == 0) targetColumnX = exitLeft.dx;
            if (p.type == 1) targetColumnX = exitMid.dx;
            if (p.type == 2) targetColumnX = exitRight.dx;

            double drift = targetColumnX - p.x;
            p.x += drift * 0.08; // Gentle snap to column
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final backgroundColor =
        isDark ? const Color(0xFF0F1426) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // LAYER 1 (Bottom): Particles
          RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: SortingParticlePainter(
                particles: particles,
                isDark: isDark,
                logoCenter: Offset(centerX, centerY),
                logoRadius: 85,
              ),
            ),
          ),

          // LAYER 2: The Logo (The Machine)
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // The M (Sorting Body)
                  Positioned(
                    bottom: 30,
                    child: Image.asset(
                      'assets/brand/bstockiconM.png',
                      color: isDark
                          ? const Color(0xFFCFD4FF)
                          : const Color(0xFF322B8C),
                      width: 140,
                    ),
                  ),
                  // The V (Hopper)
                  Positioned(
                    top: 35,
                    child: Image.asset(
                      'assets/brand/bstockiconV.png',
                      color: isDark
                          ? const Color(0xFF63D3FF)
                          : const Color(0xFF0EA5E9),
                      width: 140,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // LAYER 3: Gradient fade mask at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 150,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      backgroundColor.withOpacity(0.0),
                      backgroundColor.withOpacity(0.4),
                      backgroundColor.withOpacity(0.85),
                      backgroundColor,
                    ],
                    stops: const [0.0, 0.35, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // LAYER 4: AshReef Footer branding
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: const Center(
                child: AshReefFooter(style: FooterStyle.simple),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- DATA MODELS ---

enum ParticleState { falling, processing, sorting }

class Particle {
  int type; // 0=Tri, 1=Circ, 2=Sqr
  double x;
  double y;
  double rotation = 0;
  double rotationSpeed;
  double scale = 1.0;
  double timer = 0;
  double velocityY;
  ParticleState state;

  Particle({
    required this.type,
    required this.x,
    required this.y,
    required this.state,
    this.rotationSpeed = 0.05,
    this.velocityY = 1.0,
  });
}

// --- THE PAINTER ---

class SortingParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final bool isDark;
  final Offset logoCenter;
  final double logoRadius;

  SortingParticlePainter({
    required this.particles,
    required this.isDark,
    required this.logoCenter,
    required this.logoRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Define Palette
    final colorTri =
        isDark ? const Color(0xFF63D3FF) : const Color(0xFF0EA5E9);
    final colorCirc =
        isDark ? const Color(0xFFCFD4FF) : const Color(0xFF322B8C);
    final colorSqr =
        isDark ? const Color(0xFFFFD740) : const Color(0xFFFFC107);

    for (var p in particles) {
      if (p.scale <= 0.05) continue;

      // Hide particles inside the logo area during processing
      if (p.state == ParticleState.processing) {
        double distToLogo = sqrt(
          pow(p.x - logoCenter.dx, 2) + pow(p.y - logoCenter.dy, 2),
        );
        if (distToLogo < logoRadius) continue;
      }

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      canvas.scale(p.scale);

      if (p.type == 0) {
        // TRIANGLE -> Left Leg -> Blue
        paint.color = colorTri;
        final path = Path();
        path.moveTo(0, -8);
        path.lineTo(7, 6);
        path.lineTo(-7, 6);
        path.close();
        canvas.drawPath(path, paint);
      } else if (p.type == 1) {
        // CIRCLE -> Middle Leg -> Purple
        paint.color = colorCirc;
        canvas.drawCircle(Offset.zero, 6, paint);
      } else {
        // SQUARE -> Right Leg -> Amber
        paint.color = colorSqr;
        canvas.drawRect(const Rect.fromLTWH(-6, -6, 12, 12), paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant SortingParticlePainter oldDelegate) => true;
}

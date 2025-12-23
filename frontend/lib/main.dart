import 'package:bstock_app/providers/history_provider.dart';
import 'package:bstock_app/providers/product_provider.dart';
import 'package:bstock_app/providers/theme_provider.dart';
import 'package:bstock_app/providers/user_provider.dart';
import 'package:bstock_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/change_request_provider.dart';
import 'router/app_router.dart';

/// Global state to track splash screen behavior during cold start.
/// This ensures splash only shows once per app launch from terminated state.
class AppState {
  /// Whether the splash screen has been shown this session
  static bool hasSplashBeenShown = false;

  /// Whether the splash animation has completed and navigation is allowed
  /// This prevents the router from redirecting away before splash finishes
  static bool splashAnimationComplete = false;
}

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => ProductProvider()),
        ChangeNotifierProvider(create: (context) => ChangeRequestProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => HistoryProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppRouter? _appRouter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Create the router ONCE when dependencies are available
    // It will use refreshListenable to respond to auth changes
    _appRouter ??= AppRouter(context.read<AuthProvider>());
  }

  @override
  Widget build(BuildContext context) {
    // Only listen to theme changes for rebuilding the MaterialApp
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Wait for router to be initialized
    if (_appRouter == null) {
      return const SizedBox.shrink();
    }

    return MaterialApp.router(
      title: 'BstocK',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: _appRouter!.router,
    );
  }
}

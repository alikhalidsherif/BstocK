import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/product_detail_screen.dart';
import '../models/models.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/add_new_product_screen.dart';
import '../screens/manage_users_screen.dart';
import '../screens/edit_product_list_screen.dart';
import '../screens/edit_product_details_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/products_screen.dart';
import 'package:bstock_app/screens/barcode_scanner_screen.dart';
import 'package:bstock_app/screens/shell_screen.dart';
import 'package:bstock_app/screens/pending_requests_screen.dart';
import 'package:bstock_app/screens/change_history_screen.dart';
import 'package:bstock_app/screens/add_user_screen.dart';
import 'package:bstock_app/screens/unpaid_requests_screen.dart';
import '../screens/sales_screen.dart';
import '../screens/archived_products_screen.dart';
import 'package:bstock_app/features/splash/splash_screen.dart';

class AppRouter {
  late final GoRouter router;
  final AuthProvider authProvider;

  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final _shellNavigatorKey = GlobalKey<NavigatorState>();

  AppRouter(this.authProvider) {
    router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      refreshListenable: authProvider,
      initialLocation: '/splash',
      routes: <RouteBase>[
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return ShellScreen(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/products',
              builder: (context, state) => const ProductsScreen(),
            ),
            GoRoute(
              path: '/admin',
              builder: (context, state) => const AdminDashboardScreen(),
            ),
            GoRoute(
              path: '/unpaid-requests',
              builder: (context, state) => const UnpaidRequestsScreen(),
            ),
            GoRoute(
              path: '/sales',
              builder: (context, state) => const SalesScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/splash',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/product/:barcode',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final product = state.extra as Product?;
            if (product != null) {
              return ProductDetailScreen(product: product);
            }
            final String barcode = state.pathParameters['barcode']!;
            return ProductDetailLoader(barcode: barcode);
          }
        ),
        GoRoute(
          path: '/add-new-product',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const AddNewProductScreen(),
        ),
        GoRoute(
          path: '/manage-users',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const ManageUsersScreen(),
        ),
        GoRoute(
          path: '/admin/pending-requests',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const PendingRequestsScreen(),
        ),
        GoRoute(
          path: '/admin/history',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const ChangeHistoryScreen(),
        ),
        GoRoute(
          path: '/edit-product',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (BuildContext context, GoRouterState state) {
            return const EditProductListScreen();
          },
        ),
        GoRoute(
          path: '/edit-product-details',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (BuildContext context, GoRouterState state) {
            final product = state.extra as Product?;
            if (product == null) {
              // Redirect or show an error, for now, redirecting to the list
              return const EditProductListScreen();
            }
            return EditProductDetailsScreen(product: product);
          },
        ),
        GoRoute(
          path: '/settings',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (BuildContext context, GoRouterState state) {
            return const SettingsScreen();
          },
        ),
        GoRoute(
          path: '/scan',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (BuildContext context, GoRouterState state) {
            return const BarcodeScannerScreen();
          },
        ),
        GoRoute(
          path: '/add-user',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const AddUserScreen(),
        ),
        GoRoute(
          path: '/admin/archived-products',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const ArchivedProductsScreen(),
        ),
      ],
      redirect: (BuildContext context, GoRouterState state) {
        final AuthStatus status = authProvider.status;
        final bool loggedIn = status == AuthStatus.authenticated;
        final UserRole? userRole = authProvider.user?.role;
        final bool isAdmin = userRole == UserRole.admin;

        final bool isLoggingIn = state.matchedLocation == '/login';
        final bool isSplash = state.matchedLocation == '/splash';

        // ═══════════════════════════════════════════════════════════
        // COLD START SPLASH LOGIC
        // ═══════════════════════════════════════════════════════════
        
        // PHASE 1: First time - redirect to splash
        if (!AppState.hasSplashBeenShown) {
          AppState.hasSplashBeenShown = true;
          return '/splash';
        }
        
        // PHASE 2: Splash is showing - block ALL redirects until animation completes
        // This prevents auth changes from navigating away prematurely
        if (!AppState.splashAnimationComplete) {
          // Always stay on or go to splash while animation is running
          return isSplash ? null : '/splash';
        }

        // ═══════════════════════════════════════════════════════════
        // NORMAL AUTH ROUTING (after splash animation completes)
        // ═══════════════════════════════════════════════════════════
        
        // If still on splash after animation complete, redirect based on auth
        if (isSplash) {
          return loggedIn ? '/' : '/login';
        }
        
        // Wait for auth to initialize before redirecting
        if (status == AuthStatus.uninitialized) {
          return null;
        }

        if (!loggedIn) {
          if (isLoggingIn) return null;
          return '/login';
        }

        if (loggedIn && isLoggingIn) {
          return '/';
        }

        // Admin-only routes protection
        final adminRoutes = [
          '/admin',
          '/manage-users',
          '/edit-product',
          '/add-new-product',
          '/edit-product-details',
          '/admin/pending-requests',
          '/admin/history',
          '/add-user',
          '/admin/archived-products'
        ];
        if (adminRoutes.contains(state.matchedLocation) && !isAdmin) {
          return '/'; // Redirect non-admins trying to access admin pages
        }

        return null; // No redirect needed
      },
    );
  }
} 
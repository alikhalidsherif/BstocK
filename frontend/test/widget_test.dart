// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:bstock_app/main.dart';
import 'package:bstock_app/providers/auth_provider.dart';
import 'package:bstock_app/providers/change_request_provider.dart';
import 'package:bstock_app/providers/history_provider.dart';
import 'package:bstock_app/providers/product_provider.dart';
import 'package:bstock_app/providers/theme_provider.dart';
import 'package:bstock_app/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App boots with required providers', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => ChangeRequestProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // allow async provider initialization to settle
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.byType(MaterialApp), findsWidgets);
  });
}

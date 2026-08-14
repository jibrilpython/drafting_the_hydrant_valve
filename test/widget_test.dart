import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drafting_the_hydrant_valve/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App builds', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(child: MyApp(preferences: prefs)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.textContaining('HYDRANT'), findsWidgets);
  });
}

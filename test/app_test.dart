import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worktime_journal/app/app.dart';

void main() {
  testWidgets('shell starts in Chinese and routes between its four tabs', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: WorktimeApp()));
    await tester.pumpAndSettle();
    expect(find.text('工时手账'), findsOneWidget);
    expect(find.text('每一份努力，都值得记下'), findsOneWidget);
    expect(find.byIcon(Icons.science_outlined), findsNothing);
    await tester.tap(find.text('月历'));
    await tester.pumpAndSettle();
    expect(find.text('把努力留在日历里'), findsOneWidget);
    await tester.tap(find.text('统计'));
    await tester.pumpAndSettle();
    expect(find.text('收获慢慢积累'), findsOneWidget);
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    expect(find.text('按你的习惯来'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

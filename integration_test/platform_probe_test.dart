import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:worktime_journal/app/app.dart';
import 'package:worktime_journal/features/platform_probe/application/probe_file_codec.dart';
import 'package:worktime_journal/features/platform_probe/data/probe_database.dart';
import 'package:worktime_journal/features/platform_probe/data/probe_files.dart';
import 'package:worktime_journal/features/platform_probe/data/probe_notifications.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native SQLite and file survive a real close/reopen', (
    tester,
  ) async {
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/integration-probe.sqlite');
    var db = ProbeDatabase.open(file);
    try {
      final before = await db.readCounter();
      expect(await db.incrementCounter(), before + 1);
      await db.close();
      db = ProbeDatabase.open(file);
      expect(await db.readCounter(), before + 1);
      final exported = await ProbeFiles().createExport(before + 1);
      expect(await exported.exists(), isTrue);
      expect(ProbeFileCodec.decode(await exported.readAsBytes()), before + 1);
    } finally {
      await db.close();
      if (await file.exists()) await file.delete();
    }
  });

  testWidgets('native notification is queued, queried and cancelled', (
    tester,
  ) async {
    final notifications = ProbeNotifications();
    final zone = await notifications.initialize();
    expect(zone, isNotEmpty);
    await notifications.cancel();
    expect(await notifications.isPending(), isFalse);
    try {
      await notifications.schedule();
      expect(await notifications.isPending(), isTrue);
    } finally {
      await notifications.cancel();
    }
    expect(await notifications.isPending(), isFalse);
  });

  testWidgets('system save and open dialogs round-trip a real external file', (
    tester,
  ) async {
    // The external ADB driver operates native UI; the assertions use the real
    // plugin results and file contents, without mocking platform channels.
    final expected = DateTime.now().microsecondsSinceEpoch;
    final files = ProbeFiles();
    expect(await files.saveToUserLocation(expected), isNotNull);
    expect(await files.selectAndRead(), expected);
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('the app shell starts and navigates on the Android device', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: WorktimeApp()));
    await tester.pumpAndSettle();
    expect(find.text('工时手账'), findsOneWidget);
    await tester.tap(find.text('月历'));
    await tester.pumpAndSettle();
    expect(find.text('把努力留在日历里'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

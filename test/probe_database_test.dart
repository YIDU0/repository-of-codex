import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:worktime_journal/features/platform_probe/data/probe_database.dart';

void main() {
  test(
    'SQLite survives close/reopen and rolls back a failed transaction',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'worktime-sqlite-',
      );
      final file = File('${directory.path}/probe.sqlite');
      var db = ProbeDatabase.open(file);
      try {
        expect(await db.readCounter(), 0);
        expect(await db.incrementCounter(), 1);
        await db.close();
        db = ProbeDatabase.open(file);
        expect(await db.readCounter(), 1);
        await expectLater(
          db.transaction(() async {
            await db.incrementCounter();
            throw StateError('simulate interrupted write');
          }),
          throwsStateError,
        );
        expect(await db.readCounter(), 1);
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );
}

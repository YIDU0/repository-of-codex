import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Isolated developer fixture, never the future income database.
class ProbeDatabase extends GeneratedDatabase {
  ProbeDatabase(super.executor);

  factory ProbeDatabase.open(File file) =>
      ProbeDatabase(NativeDatabase.createInBackground(file));

  @override
  int get schemaVersion => 1;

  // This fixture uses explicit SQL; business tables will use generated schemas.
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) => customStatement(
      'CREATE TABLE probe_state ('
      'id INTEGER PRIMARY KEY CHECK (id = 1), '
      'counter INTEGER NOT NULL CHECK (counter >= 0))',
    ),
  );

  Future<int> readCounter() async {
    final row = await customSelect(
      'SELECT counter FROM probe_state WHERE id = 1',
    ).getSingleOrNull();
    return row?.read<int>('counter') ?? 0;
  }

  Future<int> incrementCounter() => transaction(() async {
    await customStatement(
      'INSERT INTO probe_state(id, counter) VALUES (1, 1) '
      'ON CONFLICT(id) DO UPDATE SET counter = counter + 1',
    );
    return readCounter();
  });
}

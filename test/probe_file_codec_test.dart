import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:worktime_journal/features/platform_probe/application/probe_file_codec.dart';

void main() {
  test('versioned platform file preserves its counter', () {
    expect(ProbeFileCodec.decode(ProbeFileCodec.encode(7)), 7);
  });

  test('bounded stream preserves input and rejects oversized chunks', () async {
    final bytes = ProbeFileCodec.encode(12);
    expect(
      await ProbeFileCodec.decodeStream(
        Stream.fromIterable([bytes.sublist(0, 8), bytes.sublist(8)]),
      ),
      12,
    );
    await expectLater(
      ProbeFileCodec.decodeStream(
        Stream.fromIterable([
          bytes,
          List.filled(ProbeFileCodec.maximumBytes, 32),
        ]),
      ),
      throwsFormatException,
    );
  });

  test('rejects newer schema, invalid payload and oversized input', () {
    for (final payload in [
      {'schemaVersion': 2, 'kind': 'worktime_platform_probe', 'counter': 7},
      {'schemaVersion': 1.0, 'kind': 'worktime_platform_probe', 'counter': 7},
      {'schemaVersion': 1, 'kind': 'worktime_platform_probe', 'counter': -1},
      {'schemaVersion': 1, 'kind': 'other', 'counter': 7},
      {'schemaVersion': 1, 'kind': 'worktime_platform_probe', 'counter': 1.5},
    ]) {
      expect(
        () => ProbeFileCodec.decode(utf8.encode(jsonEncode(payload))),
        throwsFormatException,
      );
    }
    expect(
      () => ProbeFileCodec.decode([
        ...ProbeFileCodec.encode(7),
        ...List.filled(ProbeFileCodec.maximumBytes, 32),
      ]),
      throwsFormatException,
    );
    expect(() => ProbeFileCodec.decode([0xff]), throwsFormatException);
  });
}

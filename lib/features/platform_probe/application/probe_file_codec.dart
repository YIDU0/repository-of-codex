import 'dart:convert';
import 'dart:typed_data';

/// Versioned non-personal test data; not the future wage backup format.
abstract final class ProbeFileCodec {
  static const maximumBytes = 256 * 1024;

  static Future<int> decodeStream(Stream<List<int>> chunks) async {
    final buffer = BytesBuilder(copy: false);
    await for (final chunk in chunks) {
      if (buffer.length + chunk.length > maximumBytes) {
        throw const FormatException('验证文件过大');
      }
      buffer.add(chunk);
    }
    return decode(buffer.takeBytes());
  }

  static List<int> encode(int counter) {
    if (counter < 0) throw ArgumentError.value(counter, 'counter');
    return utf8.encode(
      jsonEncode({
        'schemaVersion': 1,
        'kind': 'worktime_platform_probe',
        'counter': counter,
      }),
    );
  }

  static int decode(List<int> bytes) {
    if (bytes.length > maximumBytes) {
      throw const FormatException('验证文件过大');
    }
    final value = jsonDecode(utf8.decode(bytes));
    if (value is! Map<String, dynamic> ||
        value['schemaVersion'] is! int ||
        value['schemaVersion'] != 1 ||
        value['kind'] != 'worktime_platform_probe' ||
        value['counter'] is! int ||
        (value['counter'] as int) < 0) {
      throw const FormatException('不是受支持的平台验证文件');
    }
    return value['counter'] as int;
  }
}

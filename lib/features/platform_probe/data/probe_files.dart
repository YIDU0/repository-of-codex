import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../application/probe_file_codec.dart';

class ProbeFiles {
  Future<File> createExport(int counter) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/worktime-platform-probe.json');
    await file.writeAsBytes(ProbeFileCodec.encode(counter), flush: true);
    return file;
  }

  Future<int?> selectAndRead() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (file == null) return null;
    final size = file.lengthSync();
    if (size != null && size > ProbeFileCodec.maximumBytes) {
      throw const FormatException('验证文件过大');
    }
    return ProbeFileCodec.decodeStream(file.readAsByteStream());
  }

  Future<Uri?> saveToUserLocation(int counter) => FilePicker.saveFile(
    fileName: 'worktime-platform-probe.json',
    bytes: Uint8List.fromList(ProbeFileCodec.encode(counter)),
    mimeType: 'application/json',
  );
}

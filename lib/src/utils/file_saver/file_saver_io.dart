import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String?> saveFile(String fileName, List<int> bytes) async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = p.join(directory.path, fileName);
  final file = File(filePath);
  await file.writeAsBytes(bytes, flush: true);
  return filePath;
}



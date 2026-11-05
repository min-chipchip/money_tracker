import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

export 'package:cunning_document_scanner/cunning_document_scanner.dart' show ScannerSource;

/// Opens the system document scanner (VisionKit on iOS, ML Kit on Android),
/// which finds the receipt's edges, straightens it and crops it, and keeps
/// the results in the app's documents folder as the receipt history.
///
/// Receipts are plain files for now; once they are linked to transactions
/// they should get a drift table that stores the path.
class ReceiptScanner {
  const ReceiptScanner();

  Future<Directory> _dir() async {
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/receipts');
    await dir.create(recursive: true);
    return dir;
  }

  /// Scans one receipt and saves it. Returns null if the user cancelled.
  ///
  /// [ScannerSource.camera] opens the camera straight away;
  /// [ScannerSource.gallery] picks an existing photo instead.
  Future<File?> scan({ScannerSource source = ScannerSource.camera}) async {
    final paths = await CunningDocumentScanner.getPictures(
      noOfPages: 1,
      scannerSource: source,
    );
    if (paths == null || paths.isEmpty) return null;

    // Copy out of the scanner's temp folder, which the OS may clear.
    final dir = await _dir();
    return File(paths.first).copy('${dir.path}/${const Uuid().v4()}.jpg');
  }

  /// Every saved receipt, newest first.
  Future<List<File>> history() async {
    final dir = await _dir();
    final files = await dir.list().where((e) => e is File && e.path.endsWith('.jpg')).cast<File>().toList();
    final stamped = [for (final f in files) (f, await f.lastModified())];
    stamped.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final s in stamped) s.$1];
  }

  Future<void> delete(File receipt) => receipt.delete();
}

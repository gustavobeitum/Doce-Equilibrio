import 'dart:typed_data';

import 'package:printing/printing.dart';

abstract interface class ReportShareService {
  Future<bool> share(Uint8List bytes, String filename);
}

class NativeReportShareService implements ReportShareService {
  @override
  Future<bool> share(Uint8List bytes, String filename) {
    return Printing.sharePdf(bytes: bytes, filename: filename);
  }
}

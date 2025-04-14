import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class PdfViewerPage extends StatefulWidget {
  final String pdfPath;

  const PdfViewerPage({Key? key, required this.pdfPath}) : super(key: key);

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? localPath;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final byteData = await rootBundle.load(widget.pdfPath);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/temp.pdf');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      setState(() {
        localPath = file.path;
      });
    } catch (e) {
      print('Errore durante il caricamento del PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regolamento'),
      ),
      body: localPath == null
          ? const Center(child: CircularProgressIndicator())
          : PDFView(
              filePath: localPath, // Percorso del file PDF locale
            ),
    );
  }
}
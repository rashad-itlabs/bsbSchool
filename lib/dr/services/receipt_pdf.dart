import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'public_downloads.dart';

/// A receipt ready to be rendered. Every string here is already localised and
/// formatted: the writer knows how to lay a receipt out, not what a payment is,
/// so the wording stays with the screen that has a `BuildContext`.
class ReceiptDocument {
  /// Headline of the sheet of paper, e.g. "Ödəniş qəbzi".
  final String title;

  /// The figure the receipt is about, rendered large ("5.00 ₼").
  final String amount;
  final String amountLabel;

  /// The gateway's own wording, and whether it means the money landed.
  final String? statusLine;
  final bool success;

  final List<ReceiptSection> sections;

  /// Small print under the rule — that this was generated, not signed.
  final String footer;

  /// Name the parent sees in Downloads / Files, without the `.pdf` suffix.
  final String fileName;

  const ReceiptDocument({
    required this.title,
    required this.amount,
    required this.amountLabel,
    required this.sections,
    required this.footer,
    required this.fileName,
    this.statusLine,
    this.success = true,
  });
}

/// A titled block of label/value rows.
class ReceiptSection {
  final String? title;
  final List<(String label, String value)> rows;
  const ReceiptSection({required this.rows, this.title});
}

/// Turns a [ReceiptDocument] into a PDF on the phone and puts it where the
/// parent can find it — the public Downloads folder on Android, the Files app
/// on iOS, exactly as a downloaded library book.
///
/// Nothing is asked of the server: the receipt is built from data the card
/// screen already holds, so it works offline and needs no new endpoint.
class ReceiptPdf {
  ReceiptPdf({PublicDownloads? publicDownloads})
      : _public = publicDownloads ?? PublicDownloads();

  final PublicDownloads _public;

  /// The PDF's own fonts. A PDF carries no system font, and the standard
  /// PDF-14 faces have neither the Azerbaijani letters (ə, ş, ğ, ı) nor ₼, so
  /// Roboto travels with the app. Parsed once — it costs ~170 KB per face.
  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<void> _loadFonts() async {
    _regular ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    _bold ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );
  }

  /// Builds [document] and saves it where the parent can find it. Throws when
  /// the file cannot be written.
  Future<void> download(ReceiptDocument document) async {
    final bytes = await build(document);
    final fileName = _safeFileName(document.fileName);

    // Staged in the cache first: [PublicDownloads] copies a file, and this one
    // is the app's to clean up afterwards.
    final staged = File('${(await getTemporaryDirectory()).path}/$fileName');
    await staged.writeAsBytes(bytes, flush: true);
    try {
      await _public.save(staged, fileName);
    } finally {
      if (await staged.exists()) await staged.delete();
    }
  }

  /// The PDF bytes, without touching the file system.
  Future<Uint8List> build(ReceiptDocument document) async {
    await _loadFonts();
    final logo = await _logo();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: _regular!, bold: _bold!),
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 44, 40, 40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(document, logo),
            pw.SizedBox(height: 22),
            _amountBox(document),
            pw.SizedBox(height: 22),
            for (final section in document.sections) ...[
              _section(section),
              pw.SizedBox(height: 18),
            ],
            pw.Spacer(),
            pw.Divider(color: _line, height: 1),
            pw.SizedBox(height: 10),
            pw.Text(
              document.footer,
              style: const pw.TextStyle(fontSize: 9, color: _muted),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  pw.Widget _header(ReceiptDocument document, pw.MemoryImage? logo) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logo != null) ...[
          pw.SizedBox(width: 38, height: 38, child: pw.Image(logo)),
          pw.SizedBox(width: 12),
        ],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BRITISH SCHOOL IN BAKU',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                document.title,
                style: const pw.TextStyle(fontSize: 11, color: _muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _amountBox(ReceiptDocument document) {
    final status = document.statusLine;
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: pw.BoxDecoration(
        color: _fill,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            document.amountLabel,
            style: const pw.TextStyle(fontSize: 10, color: _muted),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            document.amount,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          if (status != null) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              status,
              style: pw.TextStyle(
                fontSize: 11,
                color: document.success ? _ok : _fail,
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _section(ReceiptSection section) {
    final title = section.title;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _muted,
              letterSpacing: 0.6,
            ),
          ),
          pw.SizedBox(height: 8),
        ],
        for (final (label, value) in section.rows) _row(label, value),
      ],
    );
  }

  pw.Widget _row(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 10, color: _muted),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// The school crest the buffet card already carries. A missing or unreadable
  /// asset only costs the receipt its logo.
  Future<pw.MemoryImage?> _logo() async {
    try {
      final data = await rootBundle.load('assets/appIcon/app_logo_foreground.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  /// Keeps the parent's file name usable on both platforms' file systems.
  static String _safeFileName(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[.\s]+|[.\s]+$'), '');
    if (cleaned.isEmpty) return 'receipt.pdf';
    return '${String.fromCharCodes(cleaned.runes.take(80)).trimRight()}.pdf';
  }

  static const _muted = PdfColor.fromInt(0xFF6B7280);
  static const _line = PdfColor.fromInt(0xFFE3E5E8);
  static const _fill = PdfColor.fromInt(0xFFF4F6F8);
  static const _ok = PdfColor.fromInt(0xFF1E8E4A);
  static const _fail = PdfColor.fromInt(0xFFD33A3A);
}

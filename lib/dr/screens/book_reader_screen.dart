import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../features/library/domain/entities/book.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';

/// Reads a library book's PDF in place. The file lives on public storage, so
/// the URL is fetched without the app's bearer token.
class BookReaderScreen extends StatefulWidget {
  final Book book;

  const BookReaderScreen({super.key, required this.book});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final _controller = PdfViewerController();

  /// Set when the document fails to load; the viewer stays blank underneath,
  /// so we cover it with our own message rather than Syncfusion's dialog.
  String? _error;
  int _page = 0;
  int _pageCount = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileUrl = widget.book.fileUrl;

    return Scaffold(
      backgroundColor: context.dr.bgDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: DrBackHeader(title: widget.book.title),
            ),
            Expanded(
              child: fileUrl == null
                  ? _message('Bu kitabın faylı yoxdur')
                  : _error != null
                      ? _message(_error!)
                      : SfPdfViewer.network(
                          fileUrl,
                          controller: _controller,
                          canShowScrollHead: false,
                          onDocumentLoaded: (details) => setState(() {
                            _pageCount = details.document.pages.count;
                            _page = _controller.pageNumber;
                          }),
                          onDocumentLoadFailed: (details) => setState(() {
                            _error = 'Kitab açılmadı: ${details.description}';
                          }),
                          onPageChanged: (details) =>
                              setState(() => _page = details.newPageNumber),
                        ),
            ),
            if (_pageCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('$_page / $_pageCount',
                    style:
                        TextStyle(fontSize: 12, color: context.dr.textMuted)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _message(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.dr.textMuted)),
        ),
      );
}

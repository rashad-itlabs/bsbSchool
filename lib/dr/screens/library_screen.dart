import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection_container.dart';
import '../../features/library/domain/entities/book.dart';
import '../../features/library/presentation/bloc/library_bloc.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';
import 'book_reader_screen.dart';
import '../../core/l10n/l10n.dart';

/// Port of `library.html`, backed by `GET /library` — search, subject pills,
/// book grid for the student's class.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LibraryBloc>()..add(const LibraryFetched()),
      child: const _LibraryView(),
    );
  }
}

class _LibraryView extends StatelessWidget {
  const _LibraryView();

  @override
  Widget build(BuildContext context) {
    return DrScaffold(
      child: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          final bloc = context.read<LibraryBloc>();

          return RefreshIndicator(
            onRefresh: () async => bloc.add(const LibraryRefreshed()),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                DrBackHeader(
                  title: state.className == null
                      ? context.l10n.libraryTitle
                      : context.l10n.libraryTitleWithClass(state.className!),
                ),
                _SearchField(
                  onChanged: (value) => bloc.add(LibrarySearchChanged(value)),
                ),
                const SizedBox(height: 12),
                const _PaidNote(),
                const SizedBox(height: 20),
                if (state.subjects.length > 1) ...[
                  DrChipBar(
                    labels: [
                      for (final subject in state.subjects)
                        context.filterLabel(subject),
                    ],
                    selectedIndex: state.subjects.indexOf(state.subject),
                    onSelected: (i) =>
                        bloc.add(LibrarySubjectSelected(state.subjects[i])),
                  ),
                  const SizedBox(height: 24),
                ],
                _Body(state: state),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final LibraryState state;
  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.books.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == LibraryStatus.error) {
      return _Message(
        text: state.errorMessage ?? context.l10n.commonError,
        onRetry: () => context.read<LibraryBloc>().add(const LibraryRefreshed()),
      );
    }

    if (state.hasNoClass) {
      return _Message(text: context.l10n.homeworkNoClass);
    }

    final books = state.visibleBooks;
    if (books.isEmpty) {
      return _Message(text: context.l10n.libraryEmpty);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
       // const DrSectionHeader(title: 'Kitablar'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.62,
          children: books.map((b) => _BookTile(book: b)).toList(),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.dr.border),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: context.dr.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              style: const TextStyle(fontSize: 14),
              onChanged: onChanged,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: context.l10n.librarySearch,
                hintStyle: TextStyle(color: context.dr.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reassurance line under the search box: the books are already paid for, so
/// nothing in this screen costs the family anything.
class _PaidNote extends StatelessWidget {
  const _PaidNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.dr.accentSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_rounded, size: 16, color: context.dr.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.librarySchoolPaid,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: context.dr.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  final Book book;
  const _BookTile({required this.book});

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookReaderScreen(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A book with no PDF has nothing to open, so it stays inert.
    final readable = book.fileUrl != null;

    return GestureDetector(
      onTap: readable ? () => _open(context) : null,
      child: Opacity(
        opacity: readable ? 1 : 0.5,
        child: _content(context),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.dr.bgSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.dr.border),
            ),
            child: book.coverUrl == null
                ? _placeholder(context)
                : Image.network(
                    book.coverUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, _, _) => _placeholder(context),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(book.author ?? book.subject ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: context.dr.textMuted)),
      ],
    );
  }

  Widget _placeholder(BuildContext context) =>
      Icon(Icons.menu_book, size: 40, color: context.dr.textMuted);
}

class _Message extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;
  const _Message({required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.dr.textMuted)),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: Text(context.l10n.commonRetry)),
          ],
        ],
      ),
    );
  }
}

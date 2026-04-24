import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mynotes/features/notes/domain/note_text_codec.dart';
import 'package:mynotes/features/notes/presentation/mynotes_theme.dart';
import 'package:mynotes/features/notes/presentation/widgets/note_card.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/utilites/dialogs/delete_dialog.dart';

typedef NoteCallback = void Function(CloudNote note);

class NotesListView extends StatelessWidget {
  const NotesListView({
    super.key,
    required this.notes,
    required this.onDeleteNote,
    required this.onArchiveNote,
    required this.onTap,
    required this.searchQuery,
    required this.recentOnly,
    required this.gridView,
    required this.selectedTagFilter,
    required this.tagColors,
    required this.onTagTap,
  });

  final Iterable<CloudNote> notes;
  final NoteCallback onDeleteNote;
  final NoteCallback onArchiveNote;
  final NoteCallback onTap;
  final String searchQuery;
  final bool recentOnly;
  final bool gridView;
  final String? selectedTagFilter;
  final Map<String, int> tagColors;
  final ValueChanged<String> onTagTap;

  Iterable<CloudNote> get _filtered {
    final q = NoteTextCodec.normalizeForSearch(searchQuery);
    final recentCutoff = DateTime.now().subtract(const Duration(days: 1));
    return notes.where((n) {
      if (recentOnly) {
        final t = n.updatedAt;
        if (t == null || t.isBefore(recentCutoff)) {
          return false;
        }
      }
      if (q.isEmpty) {
        if (selectedTagFilter == null || selectedTagFilter!.isEmpty) {
          return true;
        }
        return n.tags.contains(selectedTagFilter);
      }
      final matchesSearch = n.searchableText.contains(q);
      if (!matchesSearch) {
        return false;
      }
      if (selectedTagFilter == null || selectedTagFilter!.isEmpty) {
        return true;
      }
      return n.tags.contains(selectedTagFilter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered.toList();
    if (list.isEmpty) {
      final hasTagFilter =
          selectedTagFilter != null && selectedTagFilter!.isNotEmpty;
      return Center(
        child: Text(
          hasTagFilter
              ? 'No notes found for #$selectedTagFilter.'
              : searchQuery.trim().isEmpty
              ? (recentOnly
                    ? 'No notes from the last 7 days.'
                    : 'No notes yet.')
              : 'No notes match your search.',
          style: const TextStyle(color: MyNotesColors.muted, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (gridView) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = math.max(
            2,
            math.min(6, (width / 280).floor()),
          );
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final note = list[index];
              return _DismissibleNoteTile(
                note: note,
                onDeleteNote: onDeleteNote,
                onArchiveNote: onArchiveNote,
                child: SizedBox.expand(
                  child: NoteCard(
                    note: note,
                    onTap: () => onTap(note),
                    tagColors: tagColors,
                    isGridView: true,
                    onTagTap: onTagTap,
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final note = list[index];
        return _DismissibleNoteTile(
          note: note,
          onDeleteNote: onDeleteNote,
          onArchiveNote: onArchiveNote,
          child: NoteCard(
            note: note,
            onTap: () => onTap(note),
            tagColors: tagColors,
            isGridView: false,
            onTagTap: onTagTap,
          ),
        );
      },
    );
  }
}

class _DismissibleNoteTile extends StatelessWidget {
  const _DismissibleNoteTile({
    required this.note,
    required this.child,
    required this.onDeleteNote,
    required this.onArchiveNote,
  });

  final CloudNote note;
  final Widget child;
  final NoteCallback onDeleteNote;
  final NoteCallback onArchiveNote;

  Future<bool> _confirmArchive(BuildContext context) async {
    final label = NoteTextCodec.displayTitle(note.text);
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Archive note?'),
            content: Text(
              label.isEmpty
                  ? 'This note will be hidden from My Notes for this session.'
                  : 'Archive “$label”? It will be hidden from My Notes for this session.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Archive'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss-${note.documentId}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        final preview = NoteTextCodec.displayTitle(note.text);
        final dialogLabel = preview == 'Untitled' ? 'this note' : preview;
        if (direction == DismissDirection.endToStart) {
          return showDeleteDialog(context: context, text: dialogLabel);
        }
        if (direction == DismissDirection.startToEnd) {
          return _confirmArchive(context);
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onArchiveNote(note);
        } else {
          onDeleteNote(note);
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: MyNotesColors.muted.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.archive_outlined, color: MyNotesColors.muted),
            SizedBox(width: 8),
            Text(
              'Archive',
              style: TextStyle(
                color: MyNotesColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.red.shade700),
          ],
        ),
      ),
      child: child,
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mynotes/Views/notes/widgets/dismissible_note_tile.dart';
import 'package:mynotes/constants/mynotes_theme.dart';
import 'package:mynotes/Views/notes/widgets/note_card.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/utilites/notes/filtered.dart';

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

  @override
  Widget build(BuildContext context) {
    final list = filtered(
      searchQuery: searchQuery,
      notes: notes,
      recentOnly: recentOnly,
      selectedTagFilter: selectedTagFilter,
    ).toList();
    if (list.isEmpty) {
      final hasTagFilter =
          selectedTagFilter != null && selectedTagFilter!.isNotEmpty;
      return Center(
        child: Text(
          hasTagFilter
              ? 'No notes found for #$selectedTagFilter.'
              : searchQuery.trim().isEmpty
              ? (recentOnly ? 'No notes from the last 1 day.' : 'No notes yet.')
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
              return DismissibleNoteTile(
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
        return DismissibleNoteTile(
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
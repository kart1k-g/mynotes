import 'package:flutter/material.dart';
import 'package:mynotes/Views/notes/notes_list_view.dart';
import 'package:mynotes/utilites/notes/note_text_codec.dart';
import 'package:mynotes/constants/mynotes_theme.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/utilites/dialogs/delete_dialog.dart';
import 'package:mynotes/utilites/notes/confirm_archive.dart';

class DismissibleNoteTile extends StatelessWidget {
  const DismissibleNoteTile({
    super.key,
    required this.note,
    required this.child,
    required this.onDeleteNote,
    required this.onArchiveNote,
  });

  final CloudNote note;
  final Widget child;
  final NoteCallback onDeleteNote;
  final NoteCallback onArchiveNote;

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
          return confirmArchive(context, note);
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

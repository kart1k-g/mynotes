import 'package:flutter/material.dart';
import 'package:mynotes/utilites/notes/note_text_codec.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';

Future<bool> confirmArchive(BuildContext context, CloudNote note) async {
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

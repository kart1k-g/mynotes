import 'package:mynotes/utilites/notes/note_text_codec.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';

Iterable<CloudNote> filtered({
  required String searchQuery,
  required Iterable<CloudNote> notes,
  required bool recentOnly,
  required String? selectedTagFilter,
}) {
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
      if (selectedTagFilter == null || selectedTagFilter.isEmpty) {
        return true;
      }
      return n.tags.contains(selectedTagFilter);
    }
    final matchesSearch = n.searchableText.contains(q);
    if (!matchesSearch) {
      return false;
    }
    if (selectedTagFilter == null || selectedTagFilter.isEmpty) {
      return true;
    }
    return n.tags.contains(selectedTagFilter);
  });
}

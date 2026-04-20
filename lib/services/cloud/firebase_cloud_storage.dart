import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mynotes/features/notes/domain/note_text_codec.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/cloud_storage_constants.dart';
import 'package:mynotes/services/cloud/cloud_storage_exceptions.dart';

enum CustomTagAddResult { added, alreadyExists }

class FirebaseCloudStorage {
  FirebaseCloudStorage._sharedInstance();
  static final _shared = FirebaseCloudStorage._sharedInstance();
  factory FirebaseCloudStorage() => _shared;

  final notes = FirebaseFirestore.instance.collection("notes");
  final tags = FirebaseFirestore.instance.collection("tags");

  Future<CloudNote> createNewNote({required String ownerUserId}) async {
    final emptyText = NoteTextCodec.encodeQuill(
      title: '',
      quillDeltaJson: '[{"insert":"\\n"}]',
    );
    final tags = <String>[];
    final searchableText = NoteTextCodec.searchableText(
      emptyText,
      extraTerms: tags,
    );
    final document = await notes.add({
      textFieldName: emptyText,
      tagsFieldName: tags,
      searchableTextFieldName: searchableText,
      ownerUserIdFieldName: ownerUserId,
      isArchivedFieldName: false,
      updatedAtFieldName: FieldValue.serverTimestamp(),
    });
    final fetchedNote = await document.get();
    return CloudNote(
      documentId: fetchedNote.id,
      ownerUserId: ownerUserId,
      text: emptyText,
      tags: tags,
      searchableText: searchableText,
      isArchived: false,
    );
  }

  Stream<Iterable<CloudNote>> allNotes({required String ownerUserId}) {
    final allNotes = notes
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .snapshots()
        .map((event) {
          final list = event.docs
              .map((doc) => CloudNote.fromSnapshot(doc))
              .where((note) => !note.isArchived)
              .toList();
          list.sort((a, b) {
            final ta = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final tb = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return tb.compareTo(ta);
          });
          return list;
        });
    return allNotes;
  }

  Future<void> updateNote({
    required String documentId,
    required String text,
    required List<String> tags,
  }) async {
    try {
      final normalizedTags =
          tags
              .map((tag) => tag.trim().toLowerCase())
              .where((tag) => tag.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      final searchableText = NoteTextCodec.searchableText(
        text,
        extraTerms: normalizedTags,
      );
      await notes.doc(documentId).update({
        textFieldName: text,
        tagsFieldName: normalizedTags,
        searchableTextFieldName: searchableText,
        updatedAtFieldName: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw CouldNotUpdateNoteException();
    }
  }

  Future<void> archiveNote({required String documentId}) async {
    try {
      await notes.doc(documentId).update({isArchivedFieldName: true});
    } catch (e) {
      throw CouldNotUpdateNoteException();
    }
  }

  Future<void> deleteNote({required String documentId}) async {
    try {
      notes.doc(documentId).delete();
    } catch (e) {
      throw CouldNotDeleteNoteException();
    }
  }

  Future<CustomTagAddResult> addCustomTagForUser({
    required String ownerUserId,
    required String tag,
  }) async {
    final normalizedTag = tag.trim().toLowerCase();
    if (normalizedTag.isEmpty) {
      return CustomTagAddResult.alreadyExists;
    }

    try {
      final existingDocQuery = await tags
          .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
          .limit(1)
          .get();

      if (existingDocQuery.docs.isEmpty) {
        await tags.add({
          ownerUserIdFieldName: ownerUserId,
          customTagsListFieldName: [normalizedTag],
        });
        return CustomTagAddResult.added;
      }

      final doc = existingDocQuery.docs.first;
      final data = doc.data();
      final existingTags =
          (data[customTagsListFieldName] as List<dynamic>? ?? const [])
              .whereType<String>()
              .map((item) => item.trim().toLowerCase())
              .where((item) => item.isNotEmpty)
              .toSet();

      if (existingTags.contains(normalizedTag)) {
        return CustomTagAddResult.alreadyExists;
      }

      await tags.doc(doc.id).update({
        customTagsListFieldName: FieldValue.arrayUnion([normalizedTag]),
      });
      return CustomTagAddResult.added;
    } catch (e) {
      throw CouldNotUpdateNoteException();
    }
  }
}

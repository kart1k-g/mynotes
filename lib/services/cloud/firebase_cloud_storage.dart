import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mynotes/features/notes/domain/note_text_codec.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/cloud_storage_constants.dart';
import 'package:mynotes/services/cloud/cloud_storage_exceptions.dart';

class FirebaseCloudStorage {
  FirebaseCloudStorage._sharedInstance();
  static final _shared = FirebaseCloudStorage._sharedInstance();
  factory FirebaseCloudStorage() => _shared;

  final notes = FirebaseFirestore.instance.collection("notes");

  Future<CloudNote> createNewNote({required String ownerUserId}) async {
    final emptyText = NoteTextCodec.encodeQuill(
      title: '',
      quillDeltaJson: '[{"insert":"\\n"}]',
    );
    final searchableText = NoteTextCodec.searchableText(emptyText);
    final document = await notes.add({
      textFieldName: emptyText,
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
  }) async {
    try {
      final searchableText = NoteTextCodec.searchableText(text);
      await notes.doc(documentId).update({
        textFieldName: text,
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
}

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

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _getTagDoc(
    String ownerUserId,
  ) async {
    final existingDocQuery = await tags
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .limit(1)
        .get();
    if (existingDocQuery.docs.isEmpty) {
      return null;
    }
    return existingDocQuery.docs.first;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getOrCreateTagDoc(
    String ownerUserId,
  ) async {
    final existing = await _getTagDoc(ownerUserId);
    if (existing != null) {
      return existing;
    }
    final created = await tags.add({
      ownerUserIdFieldName: ownerUserId,
      customTagsListFieldName: const <String>[],
      customTagMetaFieldName: const <String, dynamic>{},
      archivedTagsListFieldName: const <String>[],
      archivedTagTimesFieldName: const <String, dynamic>{},
    });
    final createdSnap = await created.get();
    return createdSnap;
  }

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

  Stream<Iterable<CloudNote>> archivedNotes({required String ownerUserId}) {
    return notes
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .snapshots()
        .map((event) {
          final list = event.docs
              .map((doc) => CloudNote.fromSnapshot(doc))
              .where((note) => note.isArchived)
              .toList();
          list.sort((a, b) {
            final ta = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final tb = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return tb.compareTo(ta);
          });
          return list;
        });
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

  Future<void> restoreNote({required String documentId}) async {
    try {
      await notes.doc(documentId).update({
        isArchivedFieldName: false,
        updatedAtFieldName: FieldValue.serverTimestamp(),
      });
    } catch (_) {
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

  Future<void> deleteNotesByTag({
    required String ownerUserId,
    required String tag,
  }) async {
    final normalizedTag = tag.trim().toLowerCase();
    if (normalizedTag.isEmpty) {
      return;
    }
    try {
      final notesWithTag = await notes
          .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
          .where(tagsFieldName, arrayContains: normalizedTag)
          .get();
      for (final note in notesWithTag.docs) {
        await this.notes.doc(note.id).delete();
      }
    } catch (_) {
      throw CouldNotDeleteNoteException();
    }
  }

  Future<List<String>> getCustomTagsForUser({
    required String ownerUserId,
  }) async {
    try {
      final doc = await _getTagDoc(ownerUserId);
      if (doc == null) {
        return const [];
      }
      final data = doc.data();
      final customTags =
          (data[customTagsListFieldName] as List<dynamic>? ?? const [])
              .whereType<String>()
              .map((item) => item.trim().toLowerCase())
              .where((item) => item.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      return customTags;
    } catch (e) {
      throw CouldNotGetAllNotesException();
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
      final doc = await _getOrCreateTagDoc(ownerUserId);
      final data = doc.data() ?? <String, dynamic>{};
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

  Future<Map<String, int>> getTagColorsForUser({
    required String ownerUserId,
  }) async {
    try {
      final doc = await _getTagDoc(ownerUserId);
      if (doc == null) {
        return const {};
      }
      final data = doc.data();
      final rawMeta = data[customTagMetaFieldName];
      if (rawMeta is! Map) {
        return const {};
      }
      final result = <String, int>{};
      for (final entry in rawMeta.entries) {
        final key = entry.key.toString().trim().toLowerCase();
        final value = entry.value;
        if (key.isEmpty) {
          continue;
        }
        if (value is int) {
          result[key] = value;
        }
      }
      return result;
    } catch (_) {
      throw CouldNotGetAllNotesException();
    }
  }

  Stream<Map<String, int>> tagColors({required String ownerUserId}) {
    return tags
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .snapshots()
        .map((event) {
          if (event.docs.isEmpty) {
            return const <String, int>{};
          }
          final data = event.docs.first.data();
          final rawMeta = data[customTagMetaFieldName];
          if (rawMeta is! Map) {
            return const <String, int>{};
          }
          final result = <String, int>{};
          for (final entry in rawMeta.entries) {
            final key = entry.key.toString().trim().toLowerCase();
            final value = entry.value;
            if (key.isEmpty) {
              continue;
            }
            if (value is int) {
              result[key] = value;
            }
          }
          return result;
        });
  }

  Future<void> setTagColorForUser({
    required String ownerUserId,
    required String tag,
    required int colorValue,
  }) async {
    final normalizedTag = tag.trim().toLowerCase();
    if (normalizedTag.isEmpty) {
      return;
    }
    try {
      final doc = await _getOrCreateTagDoc(ownerUserId);
      await tags.doc(doc.id).set({
        customTagMetaFieldName: {normalizedTag: colorValue},
      }, SetOptions(merge: true));
    } catch (_) {
      throw CouldNotUpdateNoteException();
    }
  }

  Future<void> removeCustomTagForUser({
    required String ownerUserId,
    required String tag,
  }) async {
    final normalizedTag = tag.trim().toLowerCase();
    if (normalizedTag.isEmpty) {
      return;
    }
    try {
      final doc = await _getTagDoc(ownerUserId);
      if (doc == null) {
        return;
      }
      await tags.doc(doc.id).update({
        customTagsListFieldName: FieldValue.arrayRemove([normalizedTag]),
        '$customTagMetaFieldName.$normalizedTag': FieldValue.delete(),
      });
    } catch (_) {
      throw CouldNotUpdateNoteException();
    }
  }

  Stream<Set<String>> archivedTags({required String ownerUserId}) {
    return tags
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .snapshots()
        .map((event) {
          if (event.docs.isEmpty) {
            return <String>{};
          }
          final data = event.docs.first.data();
          final list =
              (data[archivedTagsListFieldName] as List<dynamic>? ?? const [])
                  .whereType<String>()
                  .map((tag) => tag.trim().toLowerCase())
                  .where((tag) => tag.isNotEmpty)
                  .toSet();
          return list;
        });
  }

  Stream<Map<String, DateTime>> archivedTagTimes({
    required String ownerUserId,
  }) {
    return tags
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .snapshots()
        .map((event) {
          if (event.docs.isEmpty) {
            return const <String, DateTime>{};
          }
          final data = event.docs.first.data();
          final raw = data[archivedTagTimesFieldName];
          if (raw is! Map) {
            return const <String, DateTime>{};
          }
          final result = <String, DateTime>{};
          for (final entry in raw.entries) {
            final key = entry.key.toString().trim().toLowerCase();
            final value = entry.value;
            if (key.isEmpty) {
              continue;
            }
            if (value is Timestamp) {
              result[key] = value.toDate();
            }
          }
          return result;
        });
  }

  Future<void> setTagArchived({
    required String ownerUserId,
    required String tag,
    required bool archived,
    bool archiveAssociatedNotes = false,
  }) async {
    final normalizedTag = tag.trim().toLowerCase();
    if (normalizedTag.isEmpty) {
      return;
    }
    try {
      final doc = await _getOrCreateTagDoc(ownerUserId);
      final tagDocRef = tags.doc(doc.id);
      if (archived) {
        await tagDocRef.set({
          archivedTagsListFieldName: FieldValue.arrayUnion([normalizedTag]),
          '$archivedTagTimesFieldName.$normalizedTag':
              FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        if (archiveAssociatedNotes) {
          final notesWithTag = await notes
              .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
              .where(tagsFieldName, arrayContains: normalizedTag)
              .get();
          for (final note in notesWithTag.docs) {
            await this.notes.doc(note.id).update({
              isArchivedFieldName: true,
              updatedAtFieldName: FieldValue.serverTimestamp(),
            });
          }
        }
      } else {
        await tagDocRef.update({
          archivedTagsListFieldName: FieldValue.arrayRemove([normalizedTag]),
          '$archivedTagTimesFieldName.$normalizedTag': FieldValue.delete(),
        });
      }
    } catch (_) {
      throw CouldNotUpdateNoteException();
    }
  }
}

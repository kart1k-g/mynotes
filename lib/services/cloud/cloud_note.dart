import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mynotes/services/cloud/cloud_storage_constants.dart';

class CloudNote {
  final String documentId;
  final String ownerUserId;
  final String text;
  final DateTime? updatedAt;
  final bool isArchived;

  CloudNote({
    required this.documentId,
    required this.ownerUserId,
    required this.text,
    this.updatedAt,
    this.isArchived = false,
  });

  CloudNote.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> snapshot)
      : documentId = snapshot.id,
        ownerUserId = snapshot.data()[ownerUserIdFieldName] as String,
        text = snapshot.data()[textFieldName] as String? ?? '',
        isArchived = snapshot.data()[isArchivedFieldName] as bool? ?? false,
        updatedAt = _timestampToDateTime(
          snapshot.data()[updatedAtFieldName],
        );

  static DateTime? _timestampToDateTime(Object? raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    return null;
  }
}

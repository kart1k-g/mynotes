import 'package:flutter/material.dart';
import 'package:mynotes/services/auth/firebase_auth_service.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';

Future<bool> archiveTag(
  String tag, {
  required BuildContext context,
  required FirebaseCloudStorage storage,
  required bool Function() callback,
}) async {
  final user = FirebaseAuthService().currentUser;
  if (user == null) {
    return false;
  }
  final option = await showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Archive tag'),
        content: Text('How should #$tag be archived?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('tag-only'),
            child: const Text('Archive tag only'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('tag-and-notes'),
            child: const Text('Archive tag + notes'),
          ),
        ],
      );
    },
  );
  if (option == null) {
    return false;
  }
  await storage.setTagArchived(
    ownerUserId: user.id,
    tag: tag,
    archived: true,
    archiveAssociatedNotes: option == 'tag-and-notes',
  );
  return callback();
}

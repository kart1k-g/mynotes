import 'package:flutter/material.dart';
import 'package:mynotes/utilites/dialogs/generic_dialog.dart';

Future<bool> showDeleteDialog({required BuildContext context, required String text}) async {
  return await showGenericDialog<bool>(
    context: context,
    title: "Delete Note",
    body: "Are you sure you want to delete $text?",
    optionBuilder: () => {"Cancel": false, "Delete": true},
  ).then((value) => value ?? false);
}

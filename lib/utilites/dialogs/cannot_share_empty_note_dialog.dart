import 'package:flutter/material.dart';
import 'package:mynotes/utilites/dialogs/generic_dialog.dart';

Future<void> showcannotShareEmptyNoteDialog({
  required BuildContext context,
}) async {
  return showGenericDialog(
    context: context,
    title: "Sharing",
    body: "You cannot share an empty note!",
    optionBuilder: () => {"Ok": null},
  );
}

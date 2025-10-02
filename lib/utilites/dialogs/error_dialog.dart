import 'package:flutter/widgets.dart';
import 'package:mynotes/utilites/dialogs/generic_dialog.dart';

Future<void> showErrorDialog({
  required BuildContext context,
  required String text,
}) async {
  return showGenericDialog<void>(
    context: context,
    title: "An error occured",
    body: text,
    optionBuilder: () => {'OK': null},
  );
}

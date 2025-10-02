import 'package:flutter/material.dart';
import 'package:mynotes/utilites/dialogs/generic_dialog.dart';

Future<bool> showLogOutDialog({required BuildContext context}) async {
  return await showGenericDialog<bool>(
    context: context,
    title: "Log Out",
    body: "Are you sure you want to log out?",
    optionBuilder: () => {"Cancel": false, "Log Out": true},
  ).then((value) => value??false);
}

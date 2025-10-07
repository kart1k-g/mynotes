import 'package:flutter/widgets.dart';
import 'package:mynotes/utilites/dialogs/generic_dialog.dart';

Future<void> showResetPasswordEmailSentDialog({
  required BuildContext context,
}) async {
  return showGenericDialog(
    context: context,
    title: "Email Sent",
    body:
        "Instructions have been sent to reset your password on the email provided.",
    optionBuilder: () => {"Ok": null},
  );
}

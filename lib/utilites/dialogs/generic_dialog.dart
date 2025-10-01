import 'package:flutter/material.dart';

typedef DialogOptionBuilder<T> = Map<String, T?> Function();

Future<T?> showGenericDialog<T>({
  required BuildContext context,
  required String title,
  required String body,
  required DialogOptionBuilder optionBuilder,
}) async {
  final options = optionBuilder();
  return showDialog<T>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: options.keys.map((key) {
          final T value = options[key];
          return TextButton(onPressed: () {
            if (value!=null){
              Navigator.of(context).pop(value);
            }else{
              Navigator.of(context).pop();
            }
          }, child: Text(key));
        }).toList(),
      );
    },
  );
}

import 'package:flutter/material.dart';

Future<void> showErrorDialog(BuildContext context, String msg){
  return showDialog(
    context: context,
    builder: (context){
      return AlertDialog(title: const Text("An error occured !"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: (){
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          )
        ],
      );
    },
  );
}
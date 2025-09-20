import 'package:flutter/material.dart';

Future<bool> showLogOutDailog(BuildContext context){
  return showDialog(
    context: context,
    builder: (context){
      return AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: (){
            Navigator.of(context).pop(false);
          }, child: const Text("Cancel")),
          TextButton(onPressed: (){
            Navigator.of(context).pop(true);
          }, child: const Text("Log Out")),
        ],
      );
    }).then((value) => value??false);
}
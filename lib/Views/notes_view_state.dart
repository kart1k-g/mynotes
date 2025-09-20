
import 'dart:developer' as devtools show log;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';

enum MenuAction{logout}

class NotesViewState extends StatefulWidget {
  const NotesViewState({super.key});

  @override
  State<NotesViewState> createState() => _NotesViewStateState();
}

class _NotesViewStateState extends State<NotesViewState> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Main UI"), 
          backgroundColor: Colors.deepPurple,
          actions: [
            PopupMenuButton<MenuAction>(
              onSelected: (value)async{
                // devtools.log(value.toString() );
                switch(value){
                  case MenuAction.logout:
                    final shouldLogOut=await showLogOutDailog(context);
                    devtools.log(shouldLogOut.toString());
                    if(shouldLogOut){
                      FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        loginRoute,
                        (_)=> false,
                      );
                    }
                }
              },
              itemBuilder: (context){
                return const [
                  PopupMenuItem<MenuAction>(
                    value: MenuAction.logout,
                    child: Text("Logout"),
                  ),
                ];
              })
          ],
      ),
      body: const Text("UI"),
  
    );
  }
}

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
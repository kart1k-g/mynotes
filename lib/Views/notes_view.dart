
import 'dart:developer' as devtools show log;
import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/enums/menu_actions.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/utilites/show_logout_view.dart';



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
                      AuthService.firebase().logOutUser();
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


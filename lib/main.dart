import 'package:flutter/material.dart';
import 'package:mynotes/Views/login_view.dart';
import 'package:mynotes/Views/notes_view.dart';
import 'package:mynotes/Views/register_view.dart';
import 'package:mynotes/Views/verify_email_view.dart';
import 'package:mynotes/constants/routes.dart';
import 'dart:developer' as devtools show log;

import 'package:mynotes/services/auth/auth_service.dart';
void main() {
  // runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // home: const RegisterView(),
      // home: const LoginView(),
      home: const HomePage(),
      // home: const NotesViewState(),
      routes: {
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) =>const RegisterView(),
        notesRoute: (context) =>const NotesViewState(),
        verificationRoute: (context) =>const VerifyEmailView(),

      }, 
    ));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthService.firebase().initalize(),
  
      builder: (context, snapshot) {
        switch(snapshot.connectionState){
          case ConnectionState.done:
            final user=AuthService.firebase().currentUser;
            // FirebaseAuth.instance.signOut();
            // devtools.log(user);
            if(user!=null){
              if(user.isEmailVerified){
                return const NotesViewState();
              }else{
                return const VerifyEmailView();
              }
            }else{
              return const LoginView();
            }
          default:
            // return const Text("Loading...");
            return CircularProgressIndicator();
        }
      },
          
    );
  }
}
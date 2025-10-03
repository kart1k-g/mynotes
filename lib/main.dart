import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/Views/login_view.dart';
import 'package:mynotes/Views/notes/create_update_note_view.dart';
import 'package:mynotes/Views/notes/notes_view.dart';
import 'package:mynotes/Views/register_view.dart';
import 'package:mynotes/Views/verify_email_view.dart';
import 'package:mynotes/constants/routes.dart';
import 'dart:developer' as devtools show log;

import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_events.dart';
import 'package:mynotes/services/auth/bloc/auth_states.dart';
import 'package:mynotes/services/auth/firebase_auth_provider.dart';
void main() {
  // runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: BlocProvider<AuthBloc>(
        // Dispatch the initialization event right here
        create: (context) => AuthBloc(FirebaseAuthProvider())..add(const AuthEventInitalize()),
        child: const HomePage(),
      ),
      routes: {
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) =>const RegisterView(),
        notesRoute: (context) =>const NotesViewState(),
        verificationRoute: (context) =>const VerifyEmailView(),
        createOrUpdateNoteRoute: (context)=> const CreateUpdateNoteView(),
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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if(state is AuthStateLoggedIn){
          return const NotesViewState();
        }else if(state is AuthStateNeedsVerificaton){
          return const VerifyEmailView();
        }else if (state is AuthStateLoggedOut){
          return const LoginView();
        }else{
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}
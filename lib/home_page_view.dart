import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/Views/login_view.dart';
import 'package:mynotes/Views/notes/notes_view.dart';
import 'package:mynotes/Views/register_view.dart';
import 'package:mynotes/Views/verify_email_view.dart';
import 'package:mynotes/helpers/loading/loading_screen.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/utilites/dialogs/error_dialog.dart';
import 'dart:developer';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) async{
        if (state is AuthLoading) {
          LoadingScreen().show(context: context, text: state.text);
        }else{
          LoadingScreen().hide();
        }

        if(state is AuthLoggedOut){
          final exception = state.exception;
          if (exception is IncorrectCredentialsAuthException){
            await showErrorDialog(context: context, text: "Invalid Credentials");
          }else if (exception is WeakPasswordAuthException){
            await showErrorDialog(context: context, text: "Weak password");
          }else if( exception is EmailAlreadyInUseAuthException){
            await showErrorDialog(context: context, text: "Email is already registered. Try logging in");
          }else if(exception is InvalidEmailAuthException){
            await showErrorDialog(context: context, text: "Enter a valid email");
          }else if (exception is GenericAuthException){
            await showErrorDialog(context: context, text: "Authentication error");
          }
        }
      },
      builder: (context, state) {
        if (state is AuthLoggedOut) {
          if (state.user!=null) {
            return VerifyEmailView();
          } else if (state.isRegistering) {
            return RegisterView();
          } else {
            return LoginView();
          }
        } else if (state is AuthLoggedIn) {
          return NotesViewState();
        }
        return Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
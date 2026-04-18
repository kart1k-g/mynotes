import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/Views/login_view.dart';
import 'package:mynotes/Views/notes/notes_view.dart';
import 'package:mynotes/Views/register_view.dart';
import 'package:mynotes/Views/reset_password_view.dart';
import 'package:mynotes/Views/verify_email_view.dart';
import 'package:mynotes/helpers/loading/loading_screen.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthLoading) {
          LoadingScreen().show(context: context, text: state.text);
        } else {
          LoadingScreen().hide();
        }
      },
      builder: (context, state) {
        if (state is AuthLoggedOut) {
          if (state.user != null) {
            return const VerifyEmailView();
          } else if (state.isRegistering) {
            return const RegisterView();
          } else {
            return const LoginView();
          }
        } else if (state is AuthLoggedIn) {
          return const NotesViewState();
        } else if (state is AuthResetingPassword) {
          return const ResetPasswordView();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _email, _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async{
        // if(state is AuthLoggedOut){
        //   final exception = state.exception;
          
        // }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Register", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.deepPurple,
        ),
        body: Column(
          children: [
            TextField(
              controller: _email,
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(hintText: "Email"),
            ),

            TextField(
              controller: _password,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(hintText: "Password"),
            ),

            TextButton(
              onPressed: () async {
                final email = _email.text;
                final password = _password.text;
                context.read<AuthBloc>().add(
                  AuthRegisterRequested(email: email, password: password),
                );
              },
              child: const Text("Register"),
            ),

            TextButton(
              onPressed: () {
                context.read<AuthBloc>().add(
                  AuthLogOutRequested(displayRegisterView: false),
                );
              },
              child: const Text("Login instead"),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/utilites/error_dialog.dart';
import 'dart:developer' as devtools;

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _email, _password;

  @override
  void initState() {
    _email=TextEditingController();
    _password=TextEditingController();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register", style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          TextField(
            controller: _email,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress ,
            decoration: InputDecoration(
              hintText: "Email"
            ),
          ),
          
          TextField(
            controller: _password,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              hintText: "Password"
            ),
          ),
          
          TextButton(
            onPressed: ()async {
              final email=_email.text;
              final password=_password.text;

              try{
                final userCredential= await AuthService.firebase().registerUser(
                  email: email,
                  password: password
                );
                devtools.log(userCredential.toString());
                await AuthService.firebase().sendEmailVerification();

                Navigator.of(context).pushNamed(
                  verificationRoute
                );
              }on WeakPasswordAuthException{
                await showErrorDialog(context: context, text: "Weak password");
              }on EmailAlreadyInUseAuthException{
                await showErrorDialog(context: context, text: "Email is already registered. Try logging in");
              }on InvalidEmailAuthException{
                await showErrorDialog(context: context, text: "Enter a valid email");
              }on GenericAuthException{
                await showErrorDialog(context: context, text: "Authentication error");

              }
            }, 
            child: const Text("Register")),
            
          TextButton(
            onPressed: (){
              Navigator.of(context).pushNamedAndRemoveUntil(
                loginRoute,
                (route)=> false,
              );
            },
            child: const Text("Login instead"),
          )
        ],
        
      ),
    );
  }
}
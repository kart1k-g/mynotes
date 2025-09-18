import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/firebase_options.dart';
import 'dart:developer' as devtools show log;
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
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
        title: const Text("Login", style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder(
        future: Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
        ),

        builder: (context, snapshot) {
          switch(snapshot.connectionState){
            case ConnectionState.done:
              return Column(
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
                        final userCredential= await FirebaseAuth.instance.signInWithEmailAndPassword(
                          email: email,
                          password: password
                        );
                        final isEmailVerified=FirebaseAuth.instance.currentUser?.emailVerified??false;
                        devtools.log(isEmailVerified.toString());
                        devtools.log(userCredential.toString());
                        if(isEmailVerified){
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            "/notes/",
                            (_)=> false,
                          );
                        }
                      }on FirebaseAuthException catch(e){
                        devtools.log("hi");
                        switch(e.code){
                          case "invalid-credential": devtools.log("invalid-credential");
                          default : devtools.log(e.code);
                        }
                      }


                      // devtools.log(userCredential);
                    }, 
                    child: const Text("Login")),

                  TextButton(onPressed: (){
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      "/register/", 
                      (route)=> false,
                    );
                  },
                  child: const Text("Register instead"))
                ],
              );
            default:
              return const Text("Loading...");
          }
        },
        
      ),
    );
  }
}
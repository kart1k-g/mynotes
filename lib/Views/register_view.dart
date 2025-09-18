import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/firebase_options.dart';
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
                        final userCredential= await FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: email,
                          password: password
                        );
                        devtools.log(userCredential.toString());
                        Navigator.of(context).pushNamedAndRemoveUntil(
                         "/verify_email/",
                         (_)=> false,
                        );
                      }on FirebaseAuthException catch(e){
                        devtools.log("Exception");
                        if(e.code=="weak-password"){
                          devtools.log("weak-password");
                        }else if(e.code=="email-already-in-use"){
                          devtools.log("email-already-in-use");
                        }else if(e.code=="invalid-email"){
                          devtools.log("invaild-email");
                        }else{
                          devtools.log(e.code);
                        }
                        
                      }
                    }, 
                    child: const Text("Register")),
                    
                  TextButton(
                    onPressed: (){
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        "/login/",
                        (route)=> false
                      );
                    },
                    child: const Text("Login instead"),
                  )
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
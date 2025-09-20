import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/firebase_options.dart';
import 'dart:developer' as devtools;

import 'package:mynotes/utilites/show_error_view.dart';
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
                        final user=FirebaseAuth.instance.currentUser;
                        await user?.sendEmailVerification();

                        Navigator.of(context).pushNamed(
                         verificationRoute
                        );
                        // .then((onValue)async{
                        //   if(!(user?.emailVerified??false)){
                        //     await user?.delete();
                        //     devtools.log("deleted");
                        //   }
                        // });
                      }on FirebaseAuthException catch(e){
                        devtools.log("Exception");
                        if(e.code=="weak-password"){
                          await showErrorDialog(context, "Weak password");
                        }else if(e.code=="email-already-in-use"){
                          await showErrorDialog(context, "Email is already registered. Try logging in");
                        }else if(e.code=="invalid-email"){
                          await showErrorDialog(context, "Enter a valid email");
                        }else{
                          await showErrorDialog(context, e.code.toString());
                        }
                      }catch(e){
                        await showErrorDialog(context, e.toString());
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
                
              );
            default:
              return const Text("Loading...");
          }
        },
        
      ),
    );
  }
}
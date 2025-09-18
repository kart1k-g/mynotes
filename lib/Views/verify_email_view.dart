
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools;
class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Email Verification"), backgroundColor: Colors.deepPurple,),
      body: Column(children: [
        Text("Verify your email first"),
        
        Text(FirebaseAuth.instance.currentUser+""),
        
        TextButton(
          onPressed: ()async{
              final user=FirebaseAuth.instance.currentUser;
              await user?.sendEmailVerification().then((_)=>{
              });
          },
          child: const Text("Send email verification")
        ),
        
        TextButton(onPressed: ()async{
          final user=FirebaseAuth.instance.currentUser;
          await user?.reload();
          final isEmailVerified=user?.emailVerified??false;
          devtools.log(isEmailVerified.toString());
          if(isEmailVerified){
            Navigator.of(context).pushNamedAndRemoveUntil(
              "/notes/",
              (_)=> false,
            );
          }
        },
        child: const Text("Email verified"),),
        
        TextButton(onPressed: (){
          //until user is verified we don't want it in the db
          FirebaseAuth.instance.currentUser?.delete();
          Navigator.of(context).pushNamedAndRemoveUntil(
            "/login/",
          (_)=>false,);
        }, child: const Text("Edit email")),
      ],),
    );
  }
}

extension on User? {
  String operator +(String other) {
    return (this?.email ?? 'No Email') + other;
  }
}


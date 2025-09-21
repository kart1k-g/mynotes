import 'package:flutter/material.dart';
import 'dart:developer' as devtools;

import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_service.dart';
class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> with WidgetsBindingObserver{
  bool _isEmailVerified=false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Email Verification"), backgroundColor: Colors.deepPurple,),
      body: Column(children: [
        Text("Email verifiaction sent on ${AuthService.firebase().currentUser?.email}"),
          
        TextButton(
          onPressed: ()async{
            await AuthService.firebase().sendEmailVerification();
          },
          child: const Text("Resend email verification")
        ),
        
        TextButton(onPressed: ()async{
          final user=AuthService.firebase().currentUser;
          await AuthService.firebase().reload();
          final isEmailVerified=user?.isEmailVerified??false;
          devtools.log(isEmailVerified.toString());
          if(isEmailVerified){
            _isEmailVerified=true;
            Navigator.of(context).pushNamedAndRemoveUntil(
              notesRoute,
              (_)=> false,
            );
          }
        },
        child: const Text("Email verified"),),
        
        TextButton(onPressed: (){
          //until user is verified we don't want it in the db
          AuthService.firebase().deleteUser();
          Navigator.of(context).pushNamedAndRemoveUntil(
            loginRoute,
          (_)=>false,);
        }, child: const Text("Use another account")),
      ],),
    );
  }
  @override
  void dispose() {
    if(!_isEmailVerified){
      AuthService.firebase().deleteUser();
      devtools.log("deleted");
    }
    super.dispose();
  }
}

// extension on User? {
//   String operator +(String other) {
//     return (this?.email ?? 'No Email') + other;
//   }
// }


import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/Views/login_view.dart';
import 'package:mynotes/Views/register_view.dart';
import 'package:mynotes/firebase_options.dart';
void main() {
  // runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // home: const RegisterView(),
      home: const LoginView(),
      // home: const HomePage(),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home", style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder(
        future: Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
        ),

        builder: (context, snapshot) {
          switch(snapshot.connectionState){
            case ConnectionState.done:
              final user=FirebaseAuth.instance.currentUser;
              print(user);
              if(user?.emailVerified??false){
                print("Email Verified");
              }else{
                print("Verify your email first");
                return const VerifyEmailView();
              }
              return const Text("Done");
            default:
              return const Text("Loading...");
          }
        },
        
      ),
    );
  }
}

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text("Verify your email first"),
      Text(FirebaseAuth.instance.currentUser+""),
      TextButton(
        onPressed: ()async{
            final user=FirebaseAuth.instance.currentUser;
            await user?.sendEmailVerification();
        },
        child: const Text("Send email verification")
      )
    ],);
  }
}

extension on User? {
  String operator +(String other) {
    return (this?.email ?? 'No Email') + other;
  }
}


import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/Views/login_view.dart';
import 'package:mynotes/Views/register_view.dart';
import 'package:mynotes/Views/verify_email_view.dart';
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
      // home: const LoginView(),
      home: const HomePage(),
      routes: {
        "/login/": (context) =>LoginView(),
        "/register/": (context) =>RegisterView(),

      },
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
      appBar: AppBar(title: const Text("Home"), backgroundColor: Colors.deepPurple,),
      body: FutureBuilder(
          future: Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
          ),
      
          builder: (context, snapshot) {
            switch(snapshot.connectionState){
              case ConnectionState.done:
                final user=FirebaseAuth.instance.currentUser;
                // print(user);
                if(user!=null){
                  if(user.emailVerified){
                    print("Email Verified");
                  }else{
                    return const VerifyEmailView();
                  }
                }else{
                  return const LoginView();
                }
                return const Text("done");
              default:
                // return const Text("Loading...");
                return CircularProgressIndicator();
            }
          },
          
        ),
    );
  }
}

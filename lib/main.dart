import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/Views/notes/create_update_note_view.dart';
import 'package:mynotes/home_page_view.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/firebase_auth_provider.dart';
// import 'package:mynotes/splash_animation.dart';
// import 'dart:developer' as devtools show log;

void main() {
  // Bloc.observer = MyBlocObserver();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    RepositoryProvider(
      create: (context) => FirebaseAuthProvider(),
      child: BlocProvider(
        create: (context) =>
            AuthBloc(provider: context.read<FirebaseAuthProvider>())
              ..add(AuthInitalize()),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Leaf Notes',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          home: const HomePage(),
          // home: SplashAnimationScreen(),
          routes: {
            createOrUpdateNoteRoute: (context) => const CreateUpdateNoteView(),
          },
        ),
      ),
    ),
  );
}

// class MyBlocObserver extends BlocObserver {
//   @override
//   void onTransition(Bloc bloc, Transition transition) {
//     super.onTransition(bloc, transition);
//     devtools.log("$bloc: $transition");
//   }
// }

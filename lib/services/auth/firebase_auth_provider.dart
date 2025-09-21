import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, FirebaseAuthException;
import 'package:firebase_core/firebase_core.dart';
import 'package:mynotes/firebase_options.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';

class FirebaseAuthProvider implements AuthProvider{
  @override
  AuthUser? get currentUser {
    final user=FirebaseAuth.instance.currentUser;
    if(user!=null){
      return AuthUser.fromFirebase(user);
    }else{
      return null;
    }
  }

  @override
  Future<void> deleteUser()async {
    final user=FirebaseAuth.instance.currentUser;
    if(user!=null){
      await user.delete();
    }else{
      throw UserNotLoggedInAuthException();
    }
  }

  @override
  Future<AuthUser> logInUser({required String email, required String password})async {
    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      final user=currentUser;
      if(user!=null){
        return user;
      }else{
        throw UserNotLoggedInAuthException();
      }
    }on FirebaseAuthException catch(e){
      if(e.code=="invalid_credential"){
        throw IncorrectCredentialsAuthException();
      }else{
        throw GenericAuthException();
      }
    }catch (e){
      throw GenericAuthException();
    }
  }

  @override
  Future<void> logOutUser()async {
    final user=FirebaseAuth.instance.currentUser;
    if(user!=null){
      await FirebaseAuth.instance.signOut();
    }else{
      throw UserNotLoggedInAuthException();
    }
  }

  @override
  Future<AuthUser> registerUser({required String email, required String password})async {
    try{
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password,);
      final user=currentUser;
      if(user!=null){
        return user;
      }else{
        throw UserNotLoggedInAuthException();
      }
    }on FirebaseAuthException catch(e){
      if(e.code=="weak-password"){
        throw WeakPasswordAuthException();
      }else if(e.code=="email-already-in-use"){
        throw EmailAlreadyInUseAuthException();
      }else if(e.code=="invalid-email"){
        throw InvalidEmailAuthException();
      }else{
        throw GenericAuthException();
      }
    }catch (e){
      throw GenericAuthException();
    }
  }

  @override
  Future<void> sendEmailVerification()async {
    final user=FirebaseAuth.instance.currentUser;
    if(user!=null){
      return await user.sendEmailVerification();
    }else{
      throw UserNotLoggedInAuthException();
    }
  }
  
  @override
  Future<void> initalize()async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  @override
  Future<void> reload()async {
    final user=FirebaseAuth.instance.currentUser;
    if(user!=null){
      await user.reload();
    }else{
      throw UserNotLoggedInAuthException();
    }
  }
} 
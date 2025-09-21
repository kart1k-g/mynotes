import 'package:mynotes/services/auth/firebase_auth_provider.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';

class AuthService implements AuthProvider{
  final AuthProvider provider;
  AuthService(this.provider);

  factory AuthService.firebase()=> AuthService(FirebaseAuthProvider());
  
  @override 
  AuthUser? get currentUser => provider.currentUser;

  @override
  Future<void> deleteUser() {
    return provider.deleteUser();
  }

  @override
  Future<AuthUser> logInUser({required String email, required String password}) {
    return provider.logInUser(email: email, password: password);
  }

  @override
  Future<void> logOutUser() {
    return provider.logOutUser();
  }

  @override
  Future<AuthUser> registerUser({required String email, required String password}) {
    return provider.registerUser(email: email, password: password);
  }

  @override
  Future<void> sendEmailVerification() {
    return provider.sendEmailVerification();
  }
  
  @override
  Future<void> initalize()=> provider.initalize();
  
  @override
  Future<void> reload()=> provider.reload();
  
}
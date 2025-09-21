import 'package:mynotes/services/auth/auth_user.dart';

abstract class AuthProvider {
  Future<void> initalize();
  AuthUser? get currentUser;
  Future<AuthUser> logInUser({
    required String email,
    required String password,
  });

  Future<AuthUser> registerUser({
    required String email,
    required String password,
  });

  Future<void> logOutUser();

  Future<void> sendEmailVerification();

  Future<void> deleteUser();

  Future<void> reload();
}

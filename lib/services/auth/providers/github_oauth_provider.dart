import 'package:firebase_auth/firebase_auth.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';

class GithubOAuthProvider {
  Future<void> logInUser() async {
    try {
      final githubAuthProvider = GithubAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      await FirebaseAuth.instance.signInWithProvider(githubAuthProvider);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw EmailAlreadyAssociatedWithAnAccountException(email: e.email);
      }
      rethrow;
    } on Exception {
      rethrow;
    }
  }
}

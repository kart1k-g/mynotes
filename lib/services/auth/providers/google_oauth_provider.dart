import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';

class GoogleOAuthProvider {
  Future<void> logInUser() async {
    try {
      GoogleSignIn google = GoogleSignIn.instance;
      await google.initialize();

      // Interactive signin process for the user
      final GoogleSignInAccount googleUser = await google.authenticate();

      final GoogleSignInAuthentication googleAuthToken =
          googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuthToken.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
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

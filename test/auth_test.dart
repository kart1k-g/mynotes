import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group("Mock Authentication", () {
    final provider = MockAuthProvider();

    test("Should not be initalised to beign with", () {
      expect(provider.isInitalised, false);
    });

    test("Cannot logout if not initalised", () {
      expect(
        provider.logOutUser(),
        throwsA(const TypeMatcher<NotInitalisedException>()),
      );
    });

    test("Should be able to be initalised", () async {
      await provider.initalize();
      expect(provider.isInitalised, true);
    });

    test(
      "Should be able to be initalised in less than 2 seconds",
      () async {
        await provider.initalize();
        expect(provider._isInitalised, true);
      },
      timeout: const Timeout(Duration(seconds: 2)),
    );

    test("User should be null after initalisation", () async {
      await provider.initalize();
      expect(provider.currentUser, null);
    });

    test("Register user should delegate to login function", () async {
      final badEmail = provider.registerUser(
        email: "foo@bar.com",
        password: "anypassword",
      );

      expect(
        badEmail,
        throwsA(const TypeMatcher<IncorrectCredentialsAuthException>()),
      );

      final badPassword = provider.registerUser(
        email: "foo@bar.com",
        password: "anypassword",
      );

      expect(
        badPassword,
        throwsA(const TypeMatcher<IncorrectCredentialsAuthException>()),
      );

      final user = await provider.registerUser(email: "foo", password: "bar");

      expect(provider.currentUser, user);
      expect(user.isEmailVerified, false);
    });

    test("Logged in user should be able to get verified", () async {
      await provider.sendEmailVerification();
      final user = provider.currentUser;
      expect(user, isNotNull);
      expect(user!.isEmailVerified, true);
    });

    test("Should be able to logout and login again", () async {
      await provider.logOutUser();
      await provider.logInUser(email: "email", password: "password");
      final user=provider.currentUser;
      expect(user, isNotNull);
    });
  });
}

class NotInitalisedException implements Exception {}

class MockAuthProvider implements AuthProvider {
  var _isInitalised = false;
  AuthUser? _user;

  bool get isInitalised => _isInitalised;

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<void> deleteUser() async {
    if (!_isInitalised) throw NotInitalisedException();
    final user = _user;
    if (user == null) throw UserNotLoggedInAuthException();
    _user = null;
    await Future.delayed(Duration(seconds: 1));
  }

  @override
  Future<void> initalize() async {
    await Future.delayed(Duration(seconds: 1));
    _isInitalised = true;
  }

  @override
  Future<AuthUser> logInUser({
    required String email,
    required String password,
  }) async {
    if (!_isInitalised) throw NotInitalisedException();
    await Future.delayed(Duration(seconds: 1));
    if (email == "foo@bar.com" || password == "foobar") {
      throw IncorrectCredentialsAuthException();
    }
    var user = AuthUser(id: "b", isEmailVerified: false, email: _user?.email);
    _user = user;
    return user;
  }

  @override
  Future<void> logOutUser() async {
    if (!_isInitalised) throw NotInitalisedException();
    if (_user == null) throw UserNotLoggedInAuthException();
    await Future.delayed(Duration(seconds: 1));
    _user = null;
  }

  @override
  Future<AuthUser> registerUser({
    required String email,
    required String password,
  }) async {
    if (!_isInitalised) throw NotInitalisedException();
    await Future.delayed(Duration(seconds: 1));
    return logInUser(email: email, password: password);
  }

  @override
  Future<void> reload() async {
    await Future.delayed(Duration(seconds: 1));
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!_isInitalised) throw NotInitalisedException();
    final user = _user;
    if (user == null) throw UserNotLoggedInAuthException();
    var newUser = AuthUser(id: "a", isEmailVerified: true, email: user.email);
    await Future.delayed(Duration(seconds: 1));
    _user = newUser;
  }
  
  @override
  Future<void> resetPassword({required String email}) async{
    if (!_isInitalised) throw NotInitalisedException();
    final user = _user;
    if (user == null) throw UserNotLoggedInAuthException();
    var newUser = AuthUser(id: "a", isEmailVerified: true, email: user.email);
    await Future.delayed(Duration(seconds: 1));
    _user = newUser;
  }
}

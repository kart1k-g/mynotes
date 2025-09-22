import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/widgets.dart';

@immutable
class AuthUser {
  final bool isEmailVerified;
  String? email;
  AuthUser({required this.isEmailVerified, required this.email});

  factory AuthUser.fromFirebase(User user) =>
      AuthUser(isEmailVerified:  user.emailVerified, email: user.email);
}

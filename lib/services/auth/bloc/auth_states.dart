import 'package:flutter/material.dart';
import 'package:mynotes/services/auth/auth_user.dart';

@immutable
abstract class AuthState {
  const AuthState();
}

class AuthStateLoading extends AuthState{
  const AuthStateLoading();
}

class AuthStateLoggedIn extends AuthState{
  final AuthUser user;
  const AuthStateLoggedIn(this.user);
}

class AuthStateLogInFailure extends AuthState{
  final Exception exception;
  const AuthStateLogInFailure({required this.exception});
}

class AuthStateNeedsVerificaton extends AuthState{
  const AuthStateNeedsVerificaton();
}

class AuthStateLoggedOut extends AuthState{
  const AuthStateLoggedOut();
}

class AuthStateLogOutFailure extends AuthState{
  final Exception exception;
  const AuthStateLogOutFailure({required this.exception});
}
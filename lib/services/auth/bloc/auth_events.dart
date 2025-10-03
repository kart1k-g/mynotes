import 'package:flutter/material.dart';

@immutable
abstract class AuthEvent{
  const AuthEvent();
}

class AuthEventInitalize extends AuthEvent{
  const AuthEventInitalize();
}

class AuthEventLogIn extends AuthEvent{
  final String email, password;
  const AuthEventLogIn(this.email, this.password);
}

class AuthEventLogOut extends AuthEvent{
  const AuthEventLogOut();
}
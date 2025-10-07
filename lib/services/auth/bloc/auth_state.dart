part of 'auth_bloc.dart';

@immutable
sealed class AuthState {}

final class AuthUninitalized extends AuthState {

  AuthUninitalized();
}

final class AuthLoading extends AuthState {
  final String text;
  AuthLoading({this.text="Loading..."});
}

final class AuthLoggedOut extends AuthState with EquatableMixin {
  final Exception? exception;
  final bool isRegistering;
  final AuthUser? user ;
  AuthLoggedOut({
    required this.exception,
    required this.isRegistering,
    required this.user,
  });

  @override
  List<Object?> get props => [exception, isRegistering, user];
}

final class AuthLoggedIn extends AuthState {
  final AuthUser user;
  AuthLoggedIn({required this.user});
}

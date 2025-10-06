part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

final class AuthInitalize extends AuthEvent{}

final class AuthLoginRequested extends AuthEvent{
  final String email;
  final String password;
  AuthLoginRequested({required this.email, required this.password});

}

final class AuthRegisterRequested extends AuthEvent{
  final String email;
  final String password;
  AuthRegisterRequested({required this.email, required this.password});
}

final class AuthEmailVerificationRequested extends AuthEvent{}

final class AuthConfirmEmailVerificationRequested extends AuthEvent{}

final class AuthLogOutRequested extends AuthEvent with EquatableMixin{
  final bool displayRegisterView;
  AuthLogOutRequested({required this.displayRegisterView});

  @override
  List<Object?> get props => [displayRegisterView];
}

final class AuthDeleteUserRequested extends AuthEvent with EquatableMixin{
  final bool displayRegisterView;

  AuthDeleteUserRequested({required this.displayRegisterView});

  @override
  List<Object?> get props => [displayRegisterView];
}
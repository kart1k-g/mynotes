import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/enums/auth_providers_types.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:mynotes/services/auth/providers/firebase_auth_provider.dart';
import 'package:mynotes/services/auth/firebase_auth_service.dart';
import 'package:mynotes/services/auth/providers/github_oauth_provider.dart';
import 'package:mynotes/services/auth/providers/google_oauth_provider.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuthProvider firebaseAuthProvider;
  final GoogleOAuthProvider googleOAuthProvider;
  final GithubOAuthProvider githubOAuthProvider;
  final _firebaseAuthService = FirebaseAuthService();
  AuthBloc({
    required this.firebaseAuthProvider,
    required this.googleOAuthProvider,
    required this.githubOAuthProvider,
  }) : super(AuthUninitalized()) {
    on<AuthInitalize>(_onAuthInitalize);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthEmailVerificationRequested>(_onAuthEmailVerificationRequested);
    on<AuthConfirmEmailVerificationRequested>(
      _onAuthConfirmEmailVerificationRequested,
    );
    on<AuthLogOutRequested>(_onAuthLogOutRequested);
    on<AuthDeleteUserRequested>(_onAuthDeleteUserRequested);
    on<AuthResetPasswordRequested>(_onAuthResetPasswordRequested);
  }

  void _onAuthInitalize(AuthInitalize event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _firebaseAuthService.initalize().timeout(
        const Duration(seconds: 10),
      );
      final user = _firebaseAuthService.currentUser;
      if (user != null) {
        if (user.isEmailVerified) {
          return emit(AuthLoggedIn(user: user));
        } else {
          await firebaseAuthProvider.sendEmailVerification();
          return emit(
            AuthLoggedOut(exception: null, isRegistering: false, user: user),
          );
        }
      } else {
        return emit(
          AuthLoggedOut(exception: null, isRegistering: false, user: null),
        );
      }
    } on Exception catch (e) {
      return emit(
        AuthLoggedOut(exception: e, isRegistering: false, user: null),
      );
    } catch (e) {
      rethrow;
    }
  }

  void _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading(text: "Verifying credentials"));
    try {
      switch (event.authProviderType) {
        case AuthProviderType.googleOAuth:
          await googleOAuthProvider.logInUser();
          break;
        case AuthProviderType.githubOAuth:
          await githubOAuthProvider.logInUser();
          break;
        case AuthProviderType.firebaseEmailAndPassword:
          await firebaseAuthProvider.logInUser(
            email: event.email!,
            password: event.password!,
          );
      }
      return emit(AuthLoggedIn(user: _firebaseAuthService.currentUser));
    } on Exception catch (e) {
      return emit(
        AuthLoggedOut(exception: e, isRegistering: false, user: null),
      );
    } catch (e) {
      rethrow;
    }
  }

  void _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading(text: "Registering"));
    try {
      await firebaseAuthProvider.registerUser(
        email: event.email,
        password: event.password,
      );
      emit(
        AuthLoggedOut(
          exception: null,
          isRegistering: false,
          user: _firebaseAuthService.currentUser,
        ),
      );
    } on Exception catch (e) {
      return emit(AuthLoggedOut(exception: e, isRegistering: true, user: null));
    } catch (e) {
      rethrow;
    }
  }

  void _onAuthEmailVerificationRequested(
    AuthEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading(text: "Sending email verification link"));
    try {
      await firebaseAuthProvider.sendEmailVerification().timeout(
        const Duration(seconds: 5),
      );
      return emit(
        AuthLoggedOut(
          exception: null,
          isRegistering: false,
          user: _firebaseAuthService.currentUser,
        ),
      );
    } on Exception catch (e) {
      return emit(
        AuthLoggedOut(
          exception: e,
          isRegistering: false,
          user: _firebaseAuthService.currentUser,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  void _onAuthConfirmEmailVerificationRequested(
    AuthConfirmEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading(text: "Confirming"));
    try {
      await _firebaseAuthService.reload().timeout(const Duration(seconds: 5));
      final user = _firebaseAuthService.currentUser;
      if (user?.isEmailVerified ?? false) {
        return emit(AuthLoggedIn(user: user!));
      } else {
        return emit(
          AuthLoggedOut(
            exception: Exception("Retry"),
            isRegistering: false,
            user: user,
          ),
        );
      }
    } on Exception catch (e) {
      return emit(
        AuthLoggedOut(
          exception: e,
          isRegistering: false,
          user: _firebaseAuthService.currentUser,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  void _onAuthLogOutRequested(
    AuthLogOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading(text: "Logging you out"));
    try {
      final user = _firebaseAuthService.currentUser;
      if (user != null) {
        await _firebaseAuthService.logOutUser();
      }
      return emit(
        AuthLoggedOut(
          exception: null,
          isRegistering: event.displayRegisterView,
          user: null,
        ),
      );
    } on Exception catch (e) {
      return emit(
        AuthLoggedOut(
          exception: e,
          isRegistering: event.displayRegisterView,
          user: null,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  void _onAuthDeleteUserRequested(
    AuthDeleteUserRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = _firebaseAuthService.currentUser;
      if (user != null) {
        await _firebaseAuthService.deleteUser();
      }
      return emit(
        AuthLoggedOut(
          exception: null,
          isRegistering: event.displayRegisterView,
          user: null,
        ),
      );
    } on Exception catch (e) {
      return emit(
        AuthLoggedOut(
          exception: e,
          isRegistering: event.displayRegisterView,
          user: _firebaseAuthService.currentUser,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  void _onAuthResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (event.email == null) {
      //user clicks to go to the reset password view
      return emit(AuthResetingPassword(exception: null));
    } else {
      emit(AuthLoading(text: "Sending the link to reset password"));
      try {
        await firebaseAuthProvider.resetPassword(email: event.email!);
        emit(AuthResetingPassword(exception: null, haveSentEmail: true));
      } on Exception catch (e) {
        return emit(AuthResetingPassword(exception: e));
      } catch (e) {
        rethrow;
      }
    }
  }
}

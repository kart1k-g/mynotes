import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:mynotes/services/auth/firebase_auth_provider.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuthProvider provider;
  AuthBloc({required this.provider}) : super(AuthUninitalized()) {
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
    await provider.initalize();
    final user = provider.currentUser;
    if (user != null) {
      if (user.isEmailVerified) {
        return emit(AuthLoggedIn(user: user));
      } else {
        await provider.sendEmailVerification();
        return emit(
          AuthLoggedOut(exception: null, isRegistering: false, user: user),
        );
      }
    } else {
      return emit(
        AuthLoggedOut(exception: null, isRegistering: false, user: null),
      );
    }
  }

  void _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> state,
  ) async {
    emit(AuthLoading(text: "Verifying credentials"));
    try {
      final user = await provider.logInUser(
        email: event.email,
        password: event.password,
      );
      return emit(AuthLoggedIn(user: user));
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
    Emitter<AuthState> state,
  ) async {
    emit(AuthLoading(text: "Registering"));
    try {
      final user = await provider.registerUser(
        email: event.email,
        password: event.password,
      );
      emit(AuthLoggedOut(exception: null, isRegistering: false, user: user));
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
      await provider.sendEmailVerification().timeout(
        const Duration(seconds: 5),
      );
      return emit(
        AuthLoggedOut(
          exception: null,
          isRegistering: false,
          user: provider.currentUser,
        ),
      );
    } on TimeoutException {
      return emit(
        AuthLoggedOut(
          exception: Exception("Error sending email verification!!"),
          isRegistering: false,
          user: provider.currentUser,
        ),
      );
    } on Exception catch (e) {
      return emit(
        AuthLoggedOut(
          exception: e,
          isRegistering: false,
          user: provider.currentUser,
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
      await provider.reload().timeout(const Duration(seconds: 5));
      final user = provider.currentUser;
      if (user?.isEmailVerified ?? false) {
        return emit(AuthLoggedIn(user: user!));
      } else {
        return emit(
          AuthLoggedOut(
            exception: Exception("Retry"),
            isRegistering: false,
            user: provider.currentUser,
          ),
        );
      }
    } on TimeoutException {
      return emit(
        AuthLoggedOut(
          exception: Exception("Retry"),
          isRegistering: false,
          user: provider.currentUser,
        ),
      );
    } on Exception catch (e) {
      return emit(
        AuthLoggedOut(
          exception: e,
          isRegistering: false,
          user: provider.currentUser,
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
      final user = provider.currentUser;
      if (user != null) {
        await provider.logOutUser();
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
      final user = provider.currentUser;
      if (user != null) {
        await provider.deleteUser();
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
          user: provider.currentUser,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  void _onAuthResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async{
    if(event.email==null){//user clicks to go to the reset password view
      return emit(AuthResetingPassword(exception: null));
    }else{
      emit(AuthLoading(text: "Sending the link to reset password"));
      try{
        await provider.resetPassword(email: event.email!);
        emit(AuthResetingPassword(exception: null, haveSentEmail: true));
      }on Exception catch(e){
        return emit(AuthResetingPassword(exception: e));
      }catch(e){
        rethrow;
      }
    }
  }
}

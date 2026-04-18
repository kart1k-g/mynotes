import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/Views/widgets/auth_input_decoration.dart';
import 'package:mynotes/Views/widgets/auth_primary_btn.dart';
import 'package:mynotes/Views/widgets/auth_ui.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/utilites/cards/inline_alert_card.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  late final TextEditingController _controller;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackgroundScaffold(
      title: 'Reset Password',
      subtitle: 'Enter your registered email to continue',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthResetingPassword && state.haveSentEmail) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 24.0),
                  child: InlineAlertCard(
                    message:
                        "Instructions have been sent to reset your password on the email provided.",
                    type: AlertType.success,
                  ),
                );
              }

              String? authErrorMessage;
              if (state is AuthResetingPassword && state.exception != null) {
                authErrorMessage =
                    "An error occurred while resetting password. Retry.";
                if (state.exception is InvalidEmailAuthException) {
                  authErrorMessage = "The email provided is invalid. Retry.";
                }
              }

              final displayMessage = _validationError ?? authErrorMessage;

              if (displayMessage != null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: InlineAlertCard(
                    message: displayMessage,
                    type: AlertType.error,
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
          TextField(
            keyboardType: TextInputType.emailAddress,
            controller: _controller,
            autofocus: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: authInputDecoration(
              label: 'Email Address',
              hintText: 'name@email.com',
              icon: Icons.mail_outline_rounded,
            ),
          ),
          const SizedBox(height: 24),
          AuthPrimaryButton(
            label: 'Send Reset Link',
            onPressed: () {
              final email = _controller.text.trim();

              setState(() {
                _validationError = null;
              });

              if (email.isEmpty) {
                setState(() {
                  _validationError = 'Please enter your email address.';
                });
                return;
              }

              context.read<AuthBloc>().add(
                AuthResetPasswordRequested(email: email),
              );
            },
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () {
                context.read<AuthBloc>().add(
                  AuthLogOutRequested(displayRegisterView: false),
                );
              },
              child: const Text(
                'Back to Login',
                style: TextStyle(
                  color: Color(0xFF009C8A),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

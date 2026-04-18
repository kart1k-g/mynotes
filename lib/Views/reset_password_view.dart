import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/Views/widgets/auth_input_decoration.dart';
import 'package:mynotes/Views/widgets/auth_primary_btn.dart';
import 'package:mynotes/Views/widgets/auth_ui.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  late final TextEditingController _controller;
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

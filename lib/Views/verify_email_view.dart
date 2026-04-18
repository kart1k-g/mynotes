import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/Views/widgets/auth_primary_btn.dart';
import 'package:mynotes/Views/widgets/auth_ui.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView>
    with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final String email = state is AuthLoggedOut
            ? (state.user?.email ?? '')
            : '';

        return AuthBackgroundScaffold(
          title: 'Verify Email',
          subtitle: 'One quick step before you continue',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9FAF7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFB6ECE3)),
                ),
                child: Text(
                  email.isEmpty
                      ? 'A verification email has been sent to your inbox.'
                      : 'A verification email has been sent to\n$email',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF213353),
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              AuthPrimaryButton(
                label: 'I\'ve Verified My Email',
                onPressed: () {
                  context.read<AuthBloc>().add(
                    AuthConfirmEmailVerificationRequested(),
                  );
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  context.read<AuthBloc>().add(
                    AuthEmailVerificationRequested(),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: const Color(0xFF009C8A),
                  side: const BorderSide(color: Color(0xFF87D8CD)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text(
                  'Resend Verification Email',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // Until email is verified, this account should not remain in storage.
                  context.read<AuthBloc>().add(
                    AuthDeleteUserRequested(displayRegisterView: false),
                  );
                  context.read<AuthBloc>().add(
                    AuthLogOutRequested(displayRegisterView: true),
                  );
                },
                child: const Text(
                  'Use Another Account',
                  style: TextStyle(
                    color: Color(0xFF5B6C87),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

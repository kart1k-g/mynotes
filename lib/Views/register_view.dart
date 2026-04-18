import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/Views/widgets/auth_input_decoration.dart';
import 'package:mynotes/Views/widgets/auth_primary_btn.dart';
import 'package:mynotes/Views/widgets/auth_secondary_btn.dart';
import 'package:mynotes/Views/widgets/auth_section_divider.dart';
import 'package:mynotes/utilites/cards/inline_alert_card.dart';
import 'package:mynotes/Views/widgets/auth_ui.dart';
import 'package:mynotes/enums/auth_providers_types.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _fullName,
      _email,
      _password,
      _confirmPassword;
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;
  String? _validationError;

  @override
  void initState() {
    _fullName = TextEditingController();
    _email = TextEditingController();
    _password = TextEditingController();
    _confirmPassword = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackgroundScaffold(
      title: 'Join LeafNotes',
      subtitle: 'Create your account to get started',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              String? authErrorMessage;
              if (state is AuthLoggedOut && state.exception != null) {
                final exception = state.exception!;
                authErrorMessage = "Registration error";
                if (exception is WeakPasswordAuthException) {
                  authErrorMessage =
                      "Weak password. Please use a stronger one.";
                } else if (exception is EmailAlreadyInUseAuthException) {
                  authErrorMessage =
                      "Email is already registered. Try logging in.";
                } else if (exception is InvalidEmailAuthException) {
                  authErrorMessage = "Enter a valid email.";
                } else if (exception is GenericAuthException) {
                  authErrorMessage = "Authentication error.";
                }
              }

              final displayMessage = _validationError ?? authErrorMessage;

              if (displayMessage != null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18.0),
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
            controller: _fullName,
            autocorrect: false,
            textCapitalization: TextCapitalization.words,
            decoration: authInputDecoration(
              label: 'Full Name',
              hintText: 'Jane Doe',
              icon: Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _email,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            decoration: authInputDecoration(
              label: 'Email Address',
              hintText: 'name@email.com',
              icon: Icons.mail_outline_rounded,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _password,
            obscureText: _isPasswordHidden,
            autocorrect: false,
            enableSuggestions: false,
            decoration: authInputDecoration(
              label: 'Password',
              hintText: 'Minimum 8 characters',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _isPasswordHidden = !_isPasswordHidden;
                  });
                },
                icon: Icon(
                  _isPasswordHidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF99A9BF),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _confirmPassword,
            obscureText: _isConfirmPasswordHidden,
            autocorrect: false,
            enableSuggestions: false,
            decoration: authInputDecoration(
              label: 'Confirm Password',
              hintText: 'Retype password',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordHidden = !_isConfirmPasswordHidden;
                  });
                },
                icon: Icon(
                  _isConfirmPasswordHidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF99A9BF),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          AuthPrimaryButton(
            label: 'Sign Up',
            onPressed: () {
              final email = _email.text.trim();
              final password = _password.text;
              final confirmPassword = _confirmPassword.text;

              setState(() {
                _validationError = null;
              });

              if (password.length < 8) {
                setState(() {
                  _validationError = 'Password must be at least 8 characters';
                });
                return;
              }

              if (password != confirmPassword) {
                setState(() {
                  _validationError = 'Passwords do not match';
                });
                return;
              }

              context.read<AuthBloc>().add(
                AuthRegisterRequested(email: email, password: password),
              );
            },
          ),
          const SizedBox(height: 22),
          const AuthSectionDivider(label: 'OR SIGN UP WITH'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AuthSecondaryButton(
                  label: 'Google',
                  logo: Image.asset(
                    "assets/icon/google_logo.webp",
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () {
                    context.read<AuthBloc>().add(
                      AuthLoginRequested(
                        authProviderType: AuthProviderType.googleOAuth,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AuthSecondaryButton(
                  label: 'GitHub',
                  logo: Image.asset(
                    "assets/icon/github_logo.webp",
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () {
                    context.read<AuthBloc>().add(
                      AuthLoginRequested(
                        authProviderType: AuthProviderType.githubOAuth,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(color: Color(0xFF506482), fontSize: 16),
              ),
              TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(
                    AuthLogOutRequested(displayRegisterView: false),
                  );
                },
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: Color(0xFF009C8A),
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

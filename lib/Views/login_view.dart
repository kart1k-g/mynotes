import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/Views/widgets/auth_input_decoration.dart';
import 'package:mynotes/Views/widgets/auth_primary_btn.dart';
import 'package:mynotes/Views/widgets/auth_secondary_btn.dart';
import 'package:mynotes/Views/widgets/auth_section_divider.dart';
import 'package:mynotes/enums/auth_providers_types.dart';
import 'package:mynotes/Views/widgets/auth_ui.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email, _password;
  bool _isPasswordHidden = true;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {},
      child: AuthBackgroundScaffold(
        title: 'Welcome Back',
        subtitle: 'Sign in to continue your journey',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthSecondaryButton(
              label: 'Login with Google',
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
            const SizedBox(height: 12),
            AuthSecondaryButton(
              label: 'Login with GitHub',
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
            const SizedBox(height: 24),
            const AuthSectionDivider(label: 'OR'),
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
                hintText: '********',
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
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(
                    AuthResetPasswordRequested(email: null),
                  );
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Color(0xFF009C8A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            AuthPrimaryButton(
              label: 'Login',
              onPressed: () {
                final email = _email.text.trim();
                final password = _password.text;

                context.read<AuthBloc>().add(
                  AuthLoginRequested(
                    email: email,
                    password: password,
                    authProviderType: AuthProviderType.firebaseEmailAndPassword,
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'New to LeafNotes? ',
                  style: TextStyle(color: Color(0xFF506482), fontSize: 16),
                ),
                TextButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(
                      AuthLogOutRequested(displayRegisterView: true),
                    );
                  },
                  child: const Text(
                    'Sign Up',
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
      ),
    );
  }
}

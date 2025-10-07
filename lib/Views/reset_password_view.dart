import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Reset Paasword"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Enter your registerd email"),

            const SizedBox(height: 10),

            TextField(
              keyboardType: TextInputType.emailAddress,
              controller: _controller,
              autofocus: true,
              enableSuggestions: false,
              decoration: InputDecoration(hintText: "Email"),
            ),

            Center(
              child: Column(
                children: [
                  TextButton(
                    onPressed: () {
                      final email = _controller.text;
                      context.read<AuthBloc>().add(
                        AuthResetPasswordRequested(email: email),
                      );
                    },
                    child: const Text("Reset Password"),
                  ),

                  TextButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(
                        AuthLogOutRequested(displayRegisterView: false),
                      );
                    },
                    child: const Text("Back to login"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

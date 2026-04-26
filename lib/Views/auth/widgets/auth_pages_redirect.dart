import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';

class AuthPagesRedirect extends StatelessWidget {
  final String text;
  final String redirectText;
  final BuildContext pageContext;
  final bool displayRegisterView;
  const AuthPagesRedirect({
    super.key,
    required this.text,
    required this.redirectText,
    required this.pageContext, required this.displayRegisterView,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text, style: TextStyle(color: Color(0xFF506482), fontSize: 16)),
        TextButton(
          onPressed: () {
            pageContext.read<AuthBloc>().add(
              AuthLogOutRequested(displayRegisterView: displayRegisterView),
            );
          },
          child: Text(
            redirectText,
            style: TextStyle(
              color: Color(0xFF009C8A),
              fontWeight: FontWeight.w700,
              fontSize: 19,
            ),
          ),
        ),
      ],
    );
  }
}

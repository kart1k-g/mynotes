import 'package:flutter/material.dart';

class AuthSectionDivider extends StatelessWidget {
  const AuthSectionDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFDCE6F0), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF66799A),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFDCE6F0), thickness: 1)),
      ],
    );
  }
}

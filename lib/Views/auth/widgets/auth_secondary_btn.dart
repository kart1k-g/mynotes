import 'package:flutter/material.dart';

class AuthSecondaryButton extends StatelessWidget {
  const AuthSecondaryButton({
    required this.label,
    required this.logo,
    required this.onPressed,
    super.key,
  });

  final String label;
  final Widget logo;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        foregroundColor: const Color(0xFF17264C),
        side: const BorderSide(color: Color(0xFFE1EAF2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: logo,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Center(child: Text(label, overflow: TextOverflow.ellipsis)),
          ),
        ],
      ),
    );
  }
}

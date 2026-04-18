import 'package:flutter/material.dart';

enum AlertType { info, error, success, warning }

class InlineAlertCard extends StatelessWidget {
  final String message;
  final AlertType type;
  final IconData? icon;

  const InlineAlertCard({
    super.key,
    required this.message,
    this.type = AlertType.info,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData defaultIcon;

    switch (type) {
      case AlertType.error:
        bgColor = const Color(0xFFFDECEA);
        borderColor = const Color(0xFFF5C6CB);
        textColor = const Color(0xFF721C24);
        defaultIcon = Icons.error_outline_rounded;
        break;
      case AlertType.success:
        bgColor = const Color(0xFFE9FAF7);
        borderColor = const Color(0xFFB6ECE3);
        textColor = const Color(0xFF009C8A);
        defaultIcon = Icons.check_circle_outline_rounded;
        break;
      case AlertType.warning:
        bgColor = const Color(0xFFFFF3E0);
        borderColor = const Color(0xFFFFCC80);
        textColor = const Color(0xFFE65100);
        defaultIcon = Icons.warning_amber_rounded;
        break;
      case AlertType.info:
        bgColor = const Color(0xFFE3F2FD);
        borderColor = const Color(0xFFBBDEFB);
        textColor = const Color(0xFF1565C0);
        defaultIcon = Icons.info_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, color: textColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

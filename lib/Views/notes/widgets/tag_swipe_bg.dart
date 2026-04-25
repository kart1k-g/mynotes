import 'package:flutter/material.dart';

class TagSwipeBg extends StatelessWidget {
  const TagSwipeBg({
    super.key,
    required this.alignLeft,
    required this.icon,
    required this.label,
    required this.color,
  });

  final bool alignLeft;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: EdgeInsets.only(
        left: alignLeft ? 20 : 0,
        right: alignLeft ? 0 : 20,
      ),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisAlignment: alignLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (!alignLeft)
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          if (!alignLeft) const SizedBox(width: 8),
          Icon(icon, color: color),
          if (alignLeft) const SizedBox(width: 8),
          if (alignLeft)
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}

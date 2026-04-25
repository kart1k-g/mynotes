import 'package:flutter/material.dart';
import 'package:mynotes/constants/mynotes_theme.dart';

class ViewToggleIcon extends StatelessWidget {
  const ViewToggleIcon({
    super.key,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? MyNotesColors.teal.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 22,
            color: selected ? MyNotesColors.teal : MyNotesColors.muted,
          ),
        ),
      ),
    );
  }
}

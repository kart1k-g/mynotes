import 'package:flutter/material.dart';
import 'package:mynotes/Views/archive_view.dart';
import 'package:mynotes/constants/mynotes_theme.dart';

typedef Callback = void Function(bool);
typedef FutureCallback = Future<void> Function({String? initialSearchQuery});

class HomepageChoiceChips extends StatelessWidget {
  final bool recentOnly;
  final String? selectedTagFilter;
  final Callback onTapAllNotes;
  final Callback onTapRecent;
  final FutureCallback openTagsManagement;

  const HomepageChoiceChips({
    super.key,
    required this.recentOnly,
    this.selectedTagFilter,
    required this.onTapAllNotes,
    required this.onTapRecent,
    required this.openTagsManagement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ChoiceChip(
          label: const Text('All Notes'),
          selected: !recentOnly,
          onSelected: onTapAllNotes,
          selectedColor: const Color(0xFFE8EEF5).withValues(alpha: 0.9),
          labelStyle: TextStyle(
            color: !recentOnly ? MyNotesColors.charcoal : MyNotesColors.muted,
            fontWeight: FontWeight.w600,
          ),
          showCheckmark: false,
          side: const BorderSide(color: MyNotesColors.divider, width: 0.5),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Recent'),
          selected: recentOnly,
          onSelected: onTapRecent,
          selectedColor: const Color(0xFFE8EEF5).withValues(alpha: 0.9),
          labelStyle: TextStyle(
            color: recentOnly ? MyNotesColors.charcoal : MyNotesColors.muted,
            fontWeight: FontWeight.w600,
          ),
          showCheckmark: false,
          side: const BorderSide(color: MyNotesColors.divider, width: 0.5),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          avatar: const Icon(
            Icons.sell_outlined,
            size: 16,
            color: MyNotesColors.muted,
          ),
          avatarBoxConstraints: const BoxConstraints(
            minWidth: 18,
            minHeight: 18,
          ),
          label: const Text('Tags'),
          selected: false,
          onSelected: (_) => openTagsManagement(),
          showCheckmark: false,
          side: const BorderSide(color: MyNotesColors.divider, width: 0.5),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          avatar: const Icon(
            Icons.archive_outlined,
            size: 16,
            color: MyNotesColors.muted,
          ),
          avatarBoxConstraints: const BoxConstraints(
            minWidth: 18,
            minHeight: 18,
          ),
          label: const Text('Archive'),
          selected: false,
          onSelected: (_) {
            Navigator.of(context).push(ArchiveScreen.route());
          },
          showCheckmark: false,
          side: const BorderSide(color: MyNotesColors.divider, width: 0.5),
        ),
      ],
    );
  }
}

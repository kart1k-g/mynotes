import 'package:flutter/material.dart';
import 'package:mynotes/Views/notes/widgets/tag_swipe_bg.dart';
import 'package:mynotes/constants/mynotes_theme.dart';

class TagTile extends StatelessWidget {
  const TagTile({
    super.key,
    required this.tag,
    required this.count,
    required this.color,
    required this.showMenu,
    required this.onTap,
    this.onEditColor,
    this.onDelete,
    this.onDeleteWithNotes,
    this.onArchive,
  });

  final String tag;
  final int count;
  final Color color;
  final bool showMenu;
  final VoidCallback onTap;
  final VoidCallback? onEditColor;
  final Future<bool> Function()? onDelete;
  final Future<bool> Function()? onDeleteWithNotes;
  final Future<bool> Function()? onArchive;

  Future<String?> _askDeleteScope(BuildContext context) async {
    final selection = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete tag'),
          content: Text(
            count > 0
                ? 'Choose what to delete for #$tag.'
                : 'Delete #$tag from your tags list?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('tag-only'),
              child: const Text('Delete Tag'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: () => Navigator.of(ctx).pop('tag-and-notes'),
              child: Text(count > 0 ? 'Delete Tag + Notes' : 'Delete'),
            ),
          ],
        );
      },
    );
    if (count == 0 && selection == 'tag-and-notes') {
      return 'tag-only';
    }
    return selection;
  }

  Future<bool> _runDeleteFlow(BuildContext context) async {
    final deleteScope = await _askDeleteScope(context);
    if (deleteScope == null) {
      return false;
    }
    if (deleteScope == 'tag-and-notes' && onDeleteWithNotes != null) {
      return onDeleteWithNotes!();
    }
    if (onDelete == null) {
      return false;
    }
    return onDelete!();
  }

  @override
  Widget build(BuildContext context) {
    final card = Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: MyNotesColors.cardBorder, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: MyNotesColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count notes',
                        style: const TextStyle(
                          fontSize: 27,
                          color: MyNotesColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showMenu)
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'color') {
                        onEditColor?.call();
                      } else if (value == 'archive') {
                        await onArchive?.call();
                      } else if (value == 'delete') {
                        await _runDeleteFlow(context);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'color',
                        child: Text('Change color'),
                      ),
                      PopupMenuItem(
                        value: 'archive',
                        child: Text('Archive tag'),
                      ),
                      PopupMenuItem(value: 'delete', child: Text('Delete tag')),
                    ],
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: MyNotesColors.muted,
                    ),
                  )
                else
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MyNotesColors.pageGrey,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: MyNotesColors.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!showMenu || onArchive == null || onDelete == null) {
      return card;
    }

    return Dismissible(
      key: ValueKey('tag-tile-$tag'),
      direction: DismissDirection.horizontal,
      background: const TagSwipeBg(
        alignLeft: true,
        icon: Icons.archive_outlined,
        label: 'Archive',
        color: MyNotesColors.muted,
      ),
      secondaryBackground: TagSwipeBg(
        alignLeft: false,
        icon: Icons.delete_forever_rounded,
        label: 'Delete',
        color: Colors.red.shade700,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          return onArchive!();
        }
        return _runDeleteFlow(context);
      },
      child: card,
    );
  }
}

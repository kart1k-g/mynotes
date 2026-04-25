import 'package:flutter/material.dart';
import 'package:mynotes/features/notes/presentation/mynotes_theme.dart';
import 'package:mynotes/services/auth/firebase_auth_service.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({
    required this.notes,
    required this.initialSelectedTag,
    this.initialSearchQuery,
    super.key,
  });

  final List<CloudNote> notes;
  final String? initialSelectedTag;
  final String? initialSearchQuery;

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  static const List<String> _defaultTags = [
    'work',
    'personal',
    'ideas',
    'todo',
    'important',
  ];

  static const List<Color> _palette = [
    Color(0xFF14B8A6),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF97316),
    Color(0xFFEAB308),
    Color(0xFFEF4444),
    Color(0xFF6366F1),
    Color(0xFF06B6D4),
    Color(0xFF84CC16),
    Color(0xFFF59E0B),
    Color(0xFF0EA5E9),
    Color(0xFFA855F7),
    Color(0xFF22C55E),
    Color(0xFFF43F5E),
  ];

  final FirebaseCloudStorage _storage = FirebaseCloudStorage();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quickAddController = TextEditingController();

  String _search = '';
  int? _quickAddColorValue;
  final Map<String, int> _tagColors = {};
  Set<String> _customTags = {};
  Set<String> _archivedTags = {};

  @override
  void initState() {
    super.initState();
    final initialSearch = widget.initialSearchQuery?.trim().toLowerCase() ?? '';
    if (initialSearch.isNotEmpty) {
      _searchController.text = initialSearch;
      _search = initialSearch;
    }
    _searchController.addListener(() {
      setState(() {
        _search = _searchController.text.trim().toLowerCase();
      });
    });
    _loadTagState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quickAddController.dispose();
    super.dispose();
  }

  Future<void> _loadTagState() async {
    final user = FirebaseAuthService().currentUser;
    if (user == null) {
      return;
    }
    try {
      final custom = await _storage.getCustomTagsForUser(ownerUserId: user.id);
      final colors = await _storage.getTagColorsForUser(ownerUserId: user.id);
      final archived = await _storage.archivedTags(ownerUserId: user.id).first;
      if (!mounted) {
        return;
      }
      setState(() {
        _customTags = custom.toSet();
        _archivedTags = archived;
        _tagColors
          ..clear()
          ..addAll(colors);
      });
    } catch (_) {}
  }

  Map<String, int> _tagCounts() {
    final counts = <String, int>{};
    for (final note in widget.notes) {
      for (final tag in note.tags) {
        if (_archivedTags.contains(tag)) {
          continue;
        }
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    for (final tag in _defaultTags) {
      if (_archivedTags.contains(tag)) {
        continue;
      }
      counts.putIfAbsent(tag, () => 0);
    }
    for (final tag in _customTags) {
      if (_archivedTags.contains(tag)) {
        continue;
      }
      counts.putIfAbsent(tag, () => 0);
    }
    return counts;
  }

  Future<void> _addQuickTag() async {
    final user = FirebaseAuthService().currentUser;
    if (user == null) {
      return;
    }
    final normalized = _quickAddController.text.trim().toLowerCase().replaceAll(
      RegExp(r'^#+'),
      '',
    );
    if (normalized.isEmpty) {
      return;
    }
    await _storage.addCustomTagForUser(ownerUserId: user.id, tag: normalized);
    final selectedColorValue =
        _quickAddColorValue ??
        _palette[normalized.hashCode.abs() % _palette.length].toARGB32();
    await _storage.setTagColorForUser(
      ownerUserId: user.id,
      tag: normalized,
      colorValue: selectedColorValue,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _customTags.add(normalized);
      _tagColors[normalized] = selectedColorValue;
      _quickAddColorValue = null;
    });
    _quickAddController.clear();
  }

  Future<int?> _showColorPickerSheet({required int initialColorValue}) async {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        int active = initialColorValue;
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Choose a color',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: MyNotesColors.charcoal,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _palette.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                      itemBuilder: (context, index) {
                        final color = _palette[index];
                        final isSelected = active == color.toARGB32();
                        return GestureDetector(
                          onTap: () {
                            setLocalState(() {
                              active = color.toARGB32();
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2.4,
                              ),
                              boxShadow: isSelected
                                  ? const [
                                      BoxShadow(
                                        color: MyNotesColors.teal,
                                        blurRadius: 0,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(active),
                        style: FilledButton.styleFrom(
                          backgroundColor: MyNotesColors.teal,
                          minimumSize: const Size.fromHeight(54),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickColorForTag(String tag) async {
    final user = FirebaseAuthService().currentUser;
    if (user == null) {
      return;
    }
    final selectedValue = await _showColorPickerSheet(
      initialColorValue: _tagColors[tag] ?? _palette.first.toARGB32(),
    );
    if (selectedValue == null) {
      return;
    }
    await _storage.setTagColorForUser(
      ownerUserId: user.id,
      tag: tag,
      colorValue: selectedValue,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _tagColors[tag] = selectedValue;
    });
  }

  Future<void> _pickQuickAddColor() async {
    final selectedValue = await _showColorPickerSheet(
      initialColorValue: _quickAddColorValue ?? _palette.first.toARGB32(),
    );
    if (selectedValue == null || !mounted) {
      return;
    }
    setState(() {
      _quickAddColorValue = selectedValue;
    });
  }

  Future<bool> _deleteTag(String tag, {bool deleteTaggedNotes = false}) async {
    final user = FirebaseAuthService().currentUser;
    if (user == null) {
      return false;
    }
    if (deleteTaggedNotes) {
      await _storage.deleteNotesByTag(ownerUserId: user.id, tag: tag);
    }
    await _storage.removeCustomTagForUser(ownerUserId: user.id, tag: tag);
    if (!mounted) {
      return false;
    }
    setState(() {
      _customTags.remove(tag);
      _tagColors.remove(tag);
    });
    return true;
  }

  Future<bool> _archiveTag(String tag) async {
    final user = FirebaseAuthService().currentUser;
    if (user == null) {
      return false;
    }
    final option = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Archive tag'),
          content: Text('How should #$tag be archived?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('tag-only'),
              child: const Text('Archive tag only'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop('tag-and-notes'),
              child: const Text('Archive tag + notes'),
            ),
          ],
        );
      },
    );
    if (option == null) {
      return false;
    }
    await _storage.setTagArchived(
      ownerUserId: user.id,
      tag: tag,
      archived: true,
      archiveAssociatedNotes: option == 'tag-and-notes',
    );
    if (!mounted) {
      return false;
    }
    setState(() {
      _archivedTags.add(tag);
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _tagCounts();
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) {
          return byCount;
        }
        return a.key.compareTo(b.key);
      });

    final visible = entries
        .where((e) => _search.isEmpty || e.key.contains(_search))
        .toList();

    Color colorFor(String tag) {
      final stored = _tagColors[tag];
      if (stored != null) {
        return Color(stored);
      }
      return _palette[tag.hashCode.abs() % _palette.length];
    }

    return Scaffold(
      backgroundColor: MyNotesColors.pageGrey,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: MyNotesColors.charcoal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search tags...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quickAddController,
                      decoration: const InputDecoration(
                        hintText: 'Quick add new tag...',
                        prefixIcon: Icon(Icons.sell_outlined),
                      ),
                      onSubmitted: (_) => _addQuickTag(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: _pickQuickAddColor,
                    tooltip: 'Pick tag color',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(52, 52),
                    ),
                    icon: Icon(
                      Icons.palette_rounded,
                      color: _quickAddColorValue != null
                          ? Color(_quickAddColorValue!)
                          : MyNotesColors.muted,
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _addQuickTag,
                    style: FilledButton.styleFrom(
                      backgroundColor: MyNotesColors.teal,
                      minimumSize: const Size(74, 52),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: MyNotesColors.divider, width: 0.5),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  children: [
                    ...visible.map((entry) {
                      final color = colorFor(entry.key);
                      return _TagTile(
                        tag: entry.key,
                        count: entry.value,
                        color: color,
                        showMenu: true,
                        onTap: () => Navigator.of(context).pop(entry.key),
                        onEditColor: () => _pickColorForTag(entry.key),
                        onDelete: () => _deleteTag(entry.key),
                        onDeleteWithNotes: () =>
                            _deleteTag(entry.key, deleteTaggedNotes: true),
                        onArchive: () => _archiveTag(entry.key),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagTile extends StatelessWidget {
  const _TagTile({
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
      background: const _TagSwipeBg(
        alignLeft: true,
        icon: Icons.archive_outlined,
        label: 'Archive',
        color: MyNotesColors.muted,
      ),
      secondaryBackground: _TagSwipeBg(
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

class _TagSwipeBg extends StatelessWidget {
  const _TagSwipeBg({
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

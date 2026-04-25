import 'package:flutter/material.dart';
import 'package:mynotes/Views/notes/widgets/tag_tile.dart';
import 'package:mynotes/constants/default_tags.dart';
import 'package:mynotes/constants/mynotes_theme.dart';
import 'package:mynotes/services/auth/firebase_auth_service.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/utilites/notes/show_color_picker_sheet.dart';
import 'package:mynotes/utilites/tags/archive_tag.dart';

class TagsView extends StatefulWidget {
  const TagsView({
    required this.notes,
    required this.initialSelectedTag,
    this.initialSearchQuery,
    super.key,
  });

  final List<CloudNote> notes;
  final String? initialSelectedTag;
  final String? initialSearchQuery;

  @override
  State<TagsView> createState() => _TagsViewState();
}

class _TagsViewState extends State<TagsView> {
  
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
    for (final tag in defaultTags) {
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
        MyNotesColors
            .palette[normalized.hashCode.abs() % MyNotesColors.palette.length]
            .toARGB32();
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

  Future<void> _pickColorForTag(String tag) async {
    final user = FirebaseAuthService().currentUser;
    if (user == null) {
      return;
    }
    final selectedValue = await showColorPickerSheet(
      initialColorValue:
          _tagColors[tag] ?? MyNotesColors.palette.first.toARGB32(),
      context: context,
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
    final selectedValue = await showColorPickerSheet(
      initialColorValue:
          _quickAddColorValue ?? MyNotesColors.palette.first.toARGB32(),
      context: context,
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
      return MyNotesColors.palette[tag.hashCode.abs() %
          MyNotesColors.palette.length];
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
                      return TagTile(
                        tag: entry.key,
                        count: entry.value,
                        color: color,
                        showMenu: true,
                        onTap: () => Navigator.of(context).pop(entry.key),
                        onEditColor: () => _pickColorForTag(entry.key),
                        onDelete: () => _deleteTag(entry.key),
                        onDeleteWithNotes: () =>
                            _deleteTag(entry.key, deleteTaggedNotes: true),
                        onArchive: () => archiveTag(
                          entry.key,
                          context: context,
                          storage: _storage,
                          callback: () {
                            if (!mounted) {
                              return false;
                            }
                            setState(() {
                              _archivedTags.add(entry.key);
                            });
                            return true;
                          },
                        ),
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

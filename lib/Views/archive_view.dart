import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/Views/notes/widgets/tag_swipe_bg.dart';
import 'package:mynotes/constants/mynotes_theme.dart';
import 'package:mynotes/features/notes/domain/note_text_codec.dart';
import 'package:mynotes/services/auth/firebase_auth_service.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';

enum ArchiveSegment { notes, tags }

class ArchiveState {
  const ArchiveState({
    this.segment = ArchiveSegment.notes,
    this.search = '',
    this.selectionMode = false,
    this.selectedNoteIds = const <String>{},
    this.selectedTags = const <String>{},
  });

  final ArchiveSegment segment;
  final String search;
  final bool selectionMode;
  final Set<String> selectedNoteIds;
  final Set<String> selectedTags;

  ArchiveState copyWith({
    ArchiveSegment? segment,
    String? search,
    bool? selectionMode,
    Set<String>? selectedNoteIds,
    Set<String>? selectedTags,
  }) {
    return ArchiveState(
      segment: segment ?? this.segment,
      search: search ?? this.search,
      selectionMode: selectionMode ?? this.selectionMode,
      selectedNoteIds: selectedNoteIds ?? this.selectedNoteIds,
      selectedTags: selectedTags ?? this.selectedTags,
    );
  }
}

class ArchiveCubit extends Cubit<ArchiveState> {
  ArchiveCubit() : super(const ArchiveState());

  void setSegment(ArchiveSegment segment) {
    emit(
      state.copyWith(
        segment: segment,
        selectedNoteIds: <String>{},
        selectedTags: <String>{},
      ),
    );
  }

  void setSearch(String value) => emit(state.copyWith(search: value));

  void toggleSelectionMode() {
    emit(
      state.copyWith(
        selectionMode: !state.selectionMode,
        selectedNoteIds: <String>{},
        selectedTags: <String>{},
      ),
    );
  }

  void toggleNoteSelection(String noteId) {
    final next = Set<String>.from(state.selectedNoteIds);
    if (!next.add(noteId)) {
      next.remove(noteId);
    }
    emit(state.copyWith(selectedNoteIds: next));
  }

  void toggleTagSelection(String tag) {
    final next = Set<String>.from(state.selectedTags);
    if (!next.add(tag)) {
      next.remove(tag);
    }
    emit(state.copyWith(selectedTags: next));
  }

  void clearSelection() {
    emit(state.copyWith(selectedNoteIds: <String>{}, selectedTags: <String>{}));
  }
}

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (_) => ArchiveCubit(),
        child: const ArchiveScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const _ArchiveView();
  }
}

class _ArchiveView extends StatefulWidget {
  const _ArchiveView();

  @override
  State<_ArchiveView> createState() => _ArchiveViewState();
}

class _ArchiveViewState extends State<_ArchiveView> {
  final FirebaseCloudStorage _storage = FirebaseCloudStorage();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  String get _userId => FirebaseAuthService().currentUser!.id;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) {
        return;
      }
      context.read<ArchiveCubit>().setSearch(
        _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArchiveCubit, ArchiveState>(
      builder: (context, state) {
        final searchHint = state.segment == ArchiveSegment.notes
            ? 'Search archived notes...'
            : 'Search archived tags...';
        return Scaffold(
          backgroundColor: MyNotesColors.archiveBg,
          bottomNavigationBar: state.selectionMode
              ? _BulkActionBar(
                  onRestoreAll: () => _onBulkRestore(context, state),
                  onDeleteAll: () => _onBulkDelete(context, state),
                )
              : null,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Icon(
                        Icons.archive_outlined,
                        color: MyNotesColors.archiveText,
                        size: 30,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Archive',
                          style: TextStyle(
                            fontSize: 50,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            color: MyNotesColors.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SegmentPicker(
                    segment: state.segment,
                    onSegmentChanged: (next) {
                      _searchController.clear();
                      context.read<ArchiveCubit>().setSegment(next);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: searchHint,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: MyNotesColors.archiveHint,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFEAECEF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: MyNotesColors.cardBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: MyNotesColors.cardBorder,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(
                  height: 1,
                  thickness: 0.8,
                  color: Color(0xFFCBD5E1),
                ),
                Expanded(
                  child: state.segment == ArchiveSegment.notes
                      ? _ArchivedNotesList(storage: _storage, userId: _userId)
                      : _ArchivedTagsList(storage: _storage, userId: _userId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onBulkRestore(BuildContext context, ArchiveState state) async {
    if (state.segment == ArchiveSegment.notes) {
      for (final id in state.selectedNoteIds) {
        await _storage.restoreNote(documentId: id);
      }
    } else {
      for (final tag in state.selectedTags) {
        await _storage.setTagArchived(
          ownerUserId: _userId,
          tag: tag,
          archived: false,
        );
      }
    }
    if (!mounted) return;
    context.read<ArchiveCubit>().clearSelection();
  }

  Future<void> _onBulkDelete(BuildContext context, ArchiveState state) async {
    if (state.segment == ArchiveSegment.notes) {
      for (final id in state.selectedNoteIds) {
        await _storage.deleteNote(documentId: id);
      }
    } else {
      for (final tag in state.selectedTags) {
        await _storage.setTagArchived(
          ownerUserId: _userId,
          tag: tag,
          archived: false,
        );
        await _storage.removeCustomTagForUser(ownerUserId: _userId, tag: tag);
      }
    }
    if (!mounted) return;
    context.read<ArchiveCubit>().clearSelection();
  }
}

class _SegmentPicker extends StatelessWidget {
  const _SegmentPicker({required this.segment, required this.onSegmentChanged});

  final ArchiveSegment segment;
  final ValueChanged<ArchiveSegment> onSegmentChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              active: segment == ArchiveSegment.notes,
              label: 'Archived Notes',
              onTap: () => onSegmentChanged(ArchiveSegment.notes),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              active: segment == ArchiveSegment.tags,
              label: 'Archived Tags',
              onTap: () => onSegmentChanged(ArchiveSegment.tags),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.active,
    required this.label,
    required this.onTap,
  });
  final bool active;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: active ? MyNotesColors.navy : MyNotesColors.archiveText,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchivedNotesList extends StatelessWidget {
  const _ArchivedNotesList({required this.storage, required this.userId});
  final FirebaseCloudStorage storage;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Iterable<CloudNote>>(
      stream: storage.archivedNotes(ownerUserId: userId),
      builder: (context, snapshot) {
        final state = context.watch<ArchiveCubit>().state;
        final query = state.search;
        final data = (snapshot.data ?? const <CloudNote>[])
            .where((n) => query.isEmpty || n.searchableText.contains(query))
            .toList();
        if (data.isEmpty) {
          return const Center(
            child: Text(
              'No archived notes',
              style: TextStyle(color: MyNotesColors.archiveHint),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemBuilder: (context, index) {
            final note = data[index];
            final selected = state.selectedNoteIds.contains(note.documentId);
            return _ArchivedNoteCard(
              note: note,
              selected: selected,
              storage: storage,
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: data.length,
        );
      },
    );
  }
}

class _ArchivedNoteCard extends StatelessWidget {
  const _ArchivedNoteCard({
    required this.note,
    required this.selected,
    required this.storage,
  });

  final CloudNote note;
  final bool selected;
  final FirebaseCloudStorage storage;

  Future<bool> _confirmUnarchive(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Unarchive note?'),
          content: const Text(
            'This note will be moved back to your notes list.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Unarchive'),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete note permanently?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ArchiveCubit>().state;
    final title = NoteTextCodec.displayTitle(note.text);
    final snippet = NoteTextCodec.snippet(note.text);
    return Dismissible(
      key: ValueKey('archive-note-${note.documentId}'),
      direction: state.selectionMode
          ? DismissDirection.none
          : DismissDirection.horizontal,
      background: TagSwipeBg(
        alignLeft: true,
        icon: Icons.restore_rounded,
        label: 'Restore',
        color: MyNotesColors.teal,
      ),
      secondaryBackground: TagSwipeBg(
        alignLeft: false,
        icon: Icons.delete_forever_rounded,
        label: 'Delete',
        color: Colors.red.shade700,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          final shouldRestore = await _confirmUnarchive(context);
          if (!shouldRestore) {
            return false;
          }
          await storage.restoreNote(documentId: note.documentId);
          return true;
        }
        final shouldDelete = await _confirmDelete(context);
        if (!shouldDelete) {
          return false;
        }
        await storage.deleteNote(documentId: note.documentId);
        return true;
      },
      child: Material(
        color: MyNotesColors.archiveCard,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: state.selectionMode
              ? () => context.read<ArchiveCubit>().toggleNoteSelection(
                  note.documentId,
                )
              : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? MyNotesColors.teal : const Color(0xFFD4DAE3),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 10, top: 2),
                    child: Checkbox(
                      value: selected,
                      onChanged: (_) => context
                          .read<ArchiveCubit>()
                          .toggleNoteSelection(note.documentId),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.archive_outlined,
                            size: 18,
                            color: MyNotesColors.archiveHint,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: MyNotesColors.archiveText,
                              ),
                            ),
                          ),
                          if (NoteTextCodec.hasAttachmentHint(note.text))
                            const Icon(
                              Icons.image_outlined,
                              color: MyNotesColors.archiveHint,
                            ),
                        ],
                      ),
                      if (snippet.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          snippet,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: MyNotesColors.archiveText,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: MyNotesColors.archiveHint,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _relativeTime(note.updatedAt),
                            style: const TextStyle(
                              color: MyNotesColors.archiveHint,
                            ),
                          ),
                          const SizedBox(width: 14),
                          if (note.tags.isNotEmpty) ...[
                            const Icon(
                              Icons.sell_outlined,
                              size: 16,
                              color: MyNotesColors.archiveHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              note.tags.first,
                              style: const TextStyle(
                                color: MyNotesColors.archiveText,
                                fontSize: 13,
                              ),
                            ),
                            if (note.tags.length > 1)
                              Text(
                                ' +${note.tags.length - 1}',
                                style: const TextStyle(
                                  color: MyNotesColors.archiveHint,
                                ),
                              ),
                          ],
                          const Spacer(),
                          if (!state.selectionMode)
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: MyNotesColors.archiveText,
                              ),
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'restore',
                                  child: Text('Restore'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete Permanently'),
                                ),
                              ],
                              onSelected: (value) async {
                                if (value == 'restore') {
                                  final shouldRestore = await _confirmUnarchive(
                                    context,
                                  );
                                  if (!shouldRestore) {
                                    return;
                                  }
                                  await storage.restoreNote(
                                    documentId: note.documentId,
                                  );
                                } else {
                                  final shouldDelete = await _confirmDelete(
                                    context,
                                  );
                                  if (!shouldDelete) {
                                    return;
                                  }
                                  await storage.deleteNote(
                                    documentId: note.documentId,
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchivedTag {
  const _ArchivedTag({
    required this.name,
    required this.count,
    required this.archivedAt,
  });

  final String name;
  final int count;
  final DateTime? archivedAt;
}

const List<Color> _archiveTagFallbackPalette = [
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

class _ArchivedTagsList extends StatelessWidget {
  const _ArchivedTagsList({required this.storage, required this.userId});
  final FirebaseCloudStorage storage;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Set<String>>(
      stream: storage.archivedTags(ownerUserId: userId),
      builder: (context, tagSnap) {
        return StreamBuilder<Map<String, DateTime>>(
          stream: storage.archivedTagTimes(ownerUserId: userId),
          builder: (context, timeSnap) {
            return StreamBuilder<Map<String, int>>(
              stream: storage.tagColors(ownerUserId: userId),
              builder: (context, colorSnap) {
                final tagColors = colorSnap.data ?? const <String, int>{};

                Color colorFor(String tag) {
                  final stored = tagColors[tag];
                  if (stored != null) {
                    return Color(stored);
                  }
                  final index =
                      tag.hashCode.abs() % _archiveTagFallbackPalette.length;
                  return _archiveTagFallbackPalette[index];
                }

                return StreamBuilder<Iterable<CloudNote>>(
                  stream: storage.archivedNotes(ownerUserId: userId),
                  builder: (context, noteSnap) {
                    final state = context.watch<ArchiveCubit>().state;
                    final query = state.search;
                    final archivedTagSet = tagSnap.data ?? <String>{};
                    final archivedNotes = noteSnap.data ?? const <CloudNote>[];
                    final tagCounts = <String, int>{};
                    for (final note in archivedNotes) {
                      for (final tag in note.tags) {
                        tagCounts.update(tag, (v) => v + 1, ifAbsent: () => 1);
                      }
                    }
                    final rows =
                        archivedTagSet
                            .map(
                              (tag) => _ArchivedTag(
                                name: tag,
                                count: tagCounts[tag] ?? 0,
                                archivedAt: timeSnap.data?[tag],
                              ),
                            )
                            .where(
                              (tag) =>
                                  query.isEmpty || tag.name.contains(query),
                            )
                            .toList()
                          ..sort((a, b) => b.count.compareTo(a.count));
                    if (rows.isEmpty) {
                      return const Center(
                        child: Text(
                          'No archived tags',
                          style: TextStyle(color: MyNotesColors.archiveHint),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        final selected = state.selectedTags.contains(row.name);
                        final taggedArchivedNoteIds = archivedNotes
                            .where((note) => note.tags.contains(row.name))
                            .map((note) => note.documentId)
                            .toList(growable: false);
                        return _ArchivedTagRow(
                          item: row,
                          color: colorFor(row.name),
                          selected: selected,
                          hasTaggedNotes: taggedArchivedNoteIds.isNotEmpty,
                          onTap: state.selectionMode
                              ? () => context
                                    .read<ArchiveCubit>()
                                    .toggleTagSelection(row.name)
                              : null,
                          onToggleSelected: () => context
                              .read<ArchiveCubit>()
                              .toggleTagSelection(row.name),
                          onRestore: () => storage.setTagArchived(
                            ownerUserId: userId,
                            tag: row.name,
                            archived: false,
                          ),
                          onRestoreTaggedNotes: () async {
                            for (final noteId in taggedArchivedNoteIds) {
                              await storage.restoreNote(documentId: noteId);
                            }
                          },
                          onDelete: () async {
                            await storage.setTagArchived(
                              ownerUserId: userId,
                              tag: row.name,
                              archived: false,
                            );
                            await storage.removeCustomTagForUser(
                              ownerUserId: userId,
                              tag: row.name,
                            );
                          },
                          onDeleteTaggedNotes: () async {
                            for (final noteId in taggedArchivedNoteIds) {
                              await storage.deleteNote(documentId: noteId);
                            }
                          },
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: rows.length,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ArchivedTagRow extends StatelessWidget {
  const _ArchivedTagRow({
    required this.item,
    required this.color,
    required this.selected,
    required this.hasTaggedNotes,
    required this.onTap,
    required this.onToggleSelected,
    required this.onRestore,
    required this.onRestoreTaggedNotes,
    required this.onDelete,
    required this.onDeleteTaggedNotes,
  });

  final _ArchivedTag item;
  final Color color;
  final bool selected;
  final bool hasTaggedNotes;
  final VoidCallback? onTap;
  final VoidCallback onToggleSelected;
  final Future<void> Function() onRestore;
  final Future<void> Function() onRestoreTaggedNotes;
  final Future<void> Function() onDelete;
  final Future<void> Function() onDeleteTaggedNotes;

  Future<String?> _askUnarchiveScope(BuildContext context) async {
    final selection = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Unarchive tag'),
          content: Text(
            hasTaggedNotes
                ? 'Choose what to unarchive for #${item.name}.'
                : 'Unarchive #${item.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('tag-only'),
              child: const Text('Unarchive Tag'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop('tag-and-notes'),
              child: Text(
                hasTaggedNotes ? 'Unarchive Tag + Notes' : 'Unarchive',
              ),
            ),
          ],
        );
      },
    );
    if (!hasTaggedNotes && selection == 'tag-and-notes') {
      return 'tag-only';
    }
    return selection;
  }

  Future<String?> _askDeleteScope(BuildContext context) async {
    final selection = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete tag'),
          content: Text(
            hasTaggedNotes
                ? 'Choose what to delete for #${item.name}. This cannot be undone.'
                : 'Delete #${item.name} permanently? This cannot be undone.',
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
              child: Text(hasTaggedNotes ? 'Delete Tag + Notes' : 'Delete'),
            ),
          ],
        );
      },
    );
    if (!hasTaggedNotes && selection == 'tag-and-notes') {
      return 'tag-only';
    }
    return selection;
  }

  Future<bool> _runUnarchiveFlow(BuildContext context) async {
    final unarchiveScope = await _askUnarchiveScope(context);
    if (unarchiveScope == null) {
      return false;
    }
    if (unarchiveScope == 'tag-and-notes') {
      await onRestoreTaggedNotes();
    }
    await onRestore();
    return true;
  }

  Future<bool> _runDeleteFlow(BuildContext context) async {
    final deleteScope = await _askDeleteScope(context);
    if (deleteScope == null) {
      return false;
    }
    if (deleteScope == 'tag-and-notes') {
      await onDeleteTaggedNotes();
    }
    await onDelete();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ArchiveCubit>().state;
    return Dismissible(
      key: ValueKey('archive-tag-${item.name}'),
      direction: state.selectionMode
          ? DismissDirection.none
          : DismissDirection.horizontal,
      background: TagSwipeBg(
        alignLeft: true,
        icon: Icons.restore_rounded,
        label: 'Restore',
        color: MyNotesColors.teal,
      ),
      secondaryBackground: TagSwipeBg(
        alignLeft: false,
        icon: Icons.delete_forever_rounded,
        label: 'Delete',
        color: Colors.red.shade700,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          return _runUnarchiveFlow(context);
        }
        return _runDeleteFlow(context);
      },
      child: Material(
        color: MyNotesColors.archiveCard,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? MyNotesColors.teal : const Color(0xFFD4DAE3),
              ),
            ),
            child: Row(
              children: [
                if (state.selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Checkbox(
                      value: selected,
                      onChanged: (_) => onToggleSelected(),
                    ),
                  ),
                const Icon(
                  Icons.archive_outlined,
                  color: MyNotesColors.archiveHint,
                ),
                const SizedBox(width: 10),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${item.name}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: MyNotesColors.archiveText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.count} notes   ·   ${_relativeTime(item.archivedAt)}',
                        style: const TextStyle(
                          color: MyNotesColors.archiveHint,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!state.selectionMode)
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: MyNotesColors.archiveText,
                    ),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'unarchive',
                        child: Text('Unarchive'),
                      ),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (value) async {
                      if (value == 'unarchive') {
                        await _runUnarchiveFlow(context);
                      } else {
                        await _runDeleteFlow(context);
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BulkActionBar extends StatelessWidget {
  const _BulkActionBar({required this.onRestoreAll, required this.onDeleteAll});
  final Future<void> Function() onRestoreAll;
  final Future<void> Function() onDeleteAll;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: MyNotesColors.cardBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRestoreAll,
                icon: const Icon(Icons.restore_rounded),
                label: const Text('Restore All'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: onDeleteAll,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('Delete All'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _relativeTime(DateTime? time) {
  if (time == null) return 'just now';
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inDays >= 30) {
    final m = (diff.inDays / 30).floor();
    return '$m month${m == 1 ? '' : 's'} ago';
  }
  if (diff.inDays >= 7) {
    final w = (diff.inDays / 7).floor();
    return '$w week${w == 1 ? '' : 's'} ago';
  }
  if (diff.inDays >= 1) {
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }
  if (diff.inHours >= 1) {
    return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  }
  return '${diff.inMinutes.clamp(1, 59)} min ago';
}
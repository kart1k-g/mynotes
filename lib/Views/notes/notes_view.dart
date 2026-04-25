import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/Views/notes/notes_list_view.dart';
import 'package:mynotes/Views/tags_view.dart';
import 'package:mynotes/Views/notes/widgets/homepage_choice_chips.dart';
import 'package:mynotes/Views/notes/widgets/view_toggle_icon.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/enums/menu_actions.dart';
import 'package:mynotes/constants/mynotes_theme.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/firebase_auth_service.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/utilites/dialogs/logout_dialog.dart';

class NotesViewState extends StatefulWidget {
  const NotesViewState({super.key});

  @override
  State<NotesViewState> createState() => _NotesViewStateState();
}

class _NotesViewStateState extends State<NotesViewState> {
  late final FirebaseCloudStorage _notesService;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  String _searchQuery = '';
  bool _recentOnly = false;
  bool _gridView = false;
  String? _selectedTagFilter;
  Map<String, int> _tagColors = const {};

  String get userId => FirebaseAuthService().currentUser!.id;

  @override
  void initState() {
    _notesService = FirebaseCloudStorage();
    _searchController.addListener(_onSearchChanged);
    _loadTagColors();
    super.initState();
  }

  Future<void> _loadTagColors() async {
    try {
      final colors = await _notesService.getTagColorsForUser(
        ownerUserId: userId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _tagColors = colors;
      });
    } catch (_) {}
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) {
        return;
      }
      final next = _searchController.text.trim();
      final normalizedQuery = next.startsWith('#') ? '' : next;
      if (normalizedQuery == _searchQuery) {
        return;
      }
      setState(() => _searchQuery = normalizedQuery);
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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).pushNamed(createOrUpdateNoteRoute);
            },
            child: const Icon(Icons.add, size: 28),
          ),
          body: SafeArea(
            child: StreamBuilder<Iterable<CloudNote>>(
              stream: _notesService.allNotes(ownerUserId: userId),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.active:
                  case ConnectionState.waiting:
                    if (snapshot.hasData) {
                      final allNotes = snapshot.data!;
                      Future<void> openTagsManagement({
                        String? initialSearchQuery,
                      }) async {
                        final selectedTag = await Navigator.of(context)
                            .push<String>(
                              MaterialPageRoute(
                                builder: (_) => TagsView(
                                  notes: allNotes.toList(),
                                  initialSelectedTag: _selectedTagFilter,
                                  initialSearchQuery: initialSearchQuery,
                                ),
                              ),
                            );
                        await _loadTagColors();
                        if (!context.mounted || selectedTag == null) {
                          return;
                        }
                        setState(() {
                          _selectedTagFilter = selectedTag;
                        });
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'My Notes',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: MyNotesColors.charcoal,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<MenuAction>(
                                  offset: const Offset(0, 48),
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      color: MyNotesColors.teal,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                  onSelected: (value) async {
                                    switch (value) {
                                      case MenuAction.logout:
                                        final shouldLogOut =
                                            await showLogOutDialog(
                                              context: context,
                                            );
                                        if (shouldLogOut && context.mounted) {
                                          context.read<AuthBloc>().add(
                                            AuthLogOutRequested(
                                              displayRegisterView: false,
                                            ),
                                          );
                                        }
                                    }
                                  },
                                  itemBuilder: (context) {
                                    return const [
                                      PopupMenuItem<MenuAction>(
                                        value: MenuAction.logout,
                                        child: Text('Logout'),
                                      ),
                                    ];
                                  },
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (value) async {
                                final trimmed = value.trim();
                                if (!trimmed.startsWith('#')) {
                                  return;
                                }
                                final normalizedTagSearch = trimmed
                                    .replaceFirst(RegExp(r'^#+'), '')
                                    .trim()
                                    .toLowerCase();
                                if (normalizedTagSearch.isEmpty) {
                                  return;
                                }
                                FocusScope.of(context).unfocus();
                                await openTagsManagement(
                                  initialSearchQuery: normalizedTagSearch,
                                );
                              },
                              decoration: const InputDecoration(
                                hintText: 'Search all notes...',
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: MyNotesColors.hint,
                                ),
                                filled: true,
                                fillColor: Color(0xFFF0F3F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(999),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 4,
                                ),
                              ),
                            ),
                          ),
                          if (_selectedTagFilter != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  10,
                                  12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE9F7F4),
                                  border: Border.all(
                                    color: MyNotesColors.teal.withValues(
                                      alpha: 0.45,
                                    ),
                                    width: 0.8,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.sell_outlined,
                                      color: MyNotesColors.teal,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: MyNotesColors.navy,
                                          ),
                                          children: [
                                            const TextSpan(
                                              text:
                                                  'Showing notes tagged with\n',
                                            ),
                                            TextSpan(
                                              text: '#$_selectedTagFilter',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedTagFilter = null;
                                        });
                                      },
                                      child: const Text(
                                        'Clear',
                                        style: TextStyle(
                                          color: MyNotesColors.tealDark,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: HomepageChoiceChips(
                                      recentOnly: _recentOnly,
                                      selectedTagFilter: _selectedTagFilter,
                                      onTapAllNotes: (_) {
                                        setState(() => _recentOnly = false);
                                      },
                                      onTapRecent: (_) {
                                        setState(() => _recentOnly = true);
                                      },
                                      openTagsManagement: openTagsManagement,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ViewToggleIcon(
                                  icon: Icons.view_list_rounded,
                                  selected: !_gridView,
                                  onTap: () =>
                                      setState(() => _gridView = false),
                                ),
                                const SizedBox(width: 8),
                                ViewToggleIcon(
                                  icon: Icons.grid_view_rounded,
                                  selected: _gridView,
                                  onTap: () => setState(() => _gridView = true),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ColoredBox(
                              color: MyNotesColors.pageGrey,
                              child: NotesListView(
                                notes: allNotes,
                                searchQuery: _searchQuery,
                                recentOnly: _recentOnly,
                                gridView: _gridView,
                                selectedTagFilter: _selectedTagFilter,
                                tagColors: _tagColors,
                                onTap: (note) {
                                  Navigator.of(context).pushNamed(
                                    createOrUpdateNoteRoute,
                                    arguments: note,
                                  );
                                },
                                onDeleteNote: (note) async {
                                  await _notesService.deleteNote(
                                    documentId: note.documentId,
                                  );
                                },
                                onArchiveNote: (note) async {
                                  await _notesService.archiveNote(
                                    documentId: note.documentId,
                                  );
                                },
                                onTagTap: (tag) {
                                  setState(() {
                                    _selectedTagFilter = tag;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  default:
                    return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        );
      },
    );
  }
}

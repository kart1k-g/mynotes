import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/Views/notes/notes_list_view.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/enums/menu_actions.dart';
import 'package:mynotes/features/notes/presentation/mynotes_theme.dart';
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

  String get userId => FirebaseAuthService().currentUser!.id;

  @override
  void initState() {
    _notesService = FirebaseCloudStorage();
    _searchController.addListener(_onSearchChanged);
    super.initState();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) {
        return;
      }
      final next = _searchController.text.trim();
      if (next == _searchQuery) {
        return;
      }
      setState(() => _searchQuery = next);
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
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('All Notes'),
                                  selected: !_recentOnly,
                                  onSelected: (_) {
                                    setState(() => _recentOnly = false);
                                  },
                                  selectedColor: const Color(
                                    0xFFE8EEF5,
                                  ).withValues(alpha: 0.9),
                                  labelStyle: TextStyle(
                                    color: !_recentOnly
                                        ? MyNotesColors.charcoal
                                        : MyNotesColors.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  showCheckmark: false,
                                  side: const BorderSide(
                                    color: MyNotesColors.divider,
                                    width: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('Recent'),
                                  selected: _recentOnly,
                                  onSelected: (_) {
                                    setState(() => _recentOnly = true);
                                  },
                                  selectedColor: const Color(
                                    0xFFE8EEF5,
                                  ).withValues(alpha: 0.9),
                                  labelStyle: TextStyle(
                                    color: _recentOnly
                                        ? MyNotesColors.charcoal
                                        : MyNotesColors.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  showCheckmark: false,
                                  side: const BorderSide(
                                    color: MyNotesColors.divider,
                                    width: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                _ViewToggleIcon(
                                  icon: Icons.view_list_rounded,
                                  selected: !_gridView,
                                  onTap: () =>
                                      setState(() => _gridView = false),
                                ),
                                const SizedBox(width: 8),
                                _ViewToggleIcon(
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

class _ViewToggleIcon extends StatelessWidget {
  const _ViewToggleIcon({
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

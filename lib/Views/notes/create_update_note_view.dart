import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:mynotes/features/notes/domain/note_text_codec.dart';
import 'package:mynotes/features/notes/presentation/mynotes_theme.dart';
import 'package:mynotes/features/notes/presentation/widgets/note_card.dart';
import 'package:mynotes/services/auth/firebase_auth_service.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/utilites/dialogs/cannot_share_empty_note_dialog.dart';
import 'package:mynotes/utilites/dialogs/delete_dialog.dart';
import 'package:mynotes/utilites/generics/get_argument.dart';
import 'package:share_plus/share_plus.dart';

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({super.key});

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateUpdateNoteView> {
  CloudNote? _note;
  Future<CloudNote>? _noteFuture;

  late final FirebaseCloudStorage _notesService;
  late final TextEditingController _titleController;
  late QuillController _quillController;
  late final FocusNode _editorFocus;
  late final ScrollController _editorScrollController;

  Timer? _debounce;
  bool _suppressSave = true;
  bool _listenersAttached = false;
  bool _isSaving = false;
  bool _isSaved = true;
  bool _showExpandedToolbar = false;

  @override
  void initState() {
    _notesService = FirebaseCloudStorage();
    _titleController = TextEditingController();
    _quillController = QuillController.basic();
    _editorFocus = FocusNode();
    _editorScrollController = ScrollController();
    _editorFocus.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.removeListener(_onTextChanged);
    _quillController.removeListener(_onTextChanged);
    _deleteNoteIfTextIsEmpty();
    _saveNoteIfTextIsNotEmpty();
    _titleController.dispose();
    _quillController.dispose();
    _editorFocus.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  Document _documentFromStoredText(String text) {
    final quillJson = NoteTextCodec.decodeQuillDeltaJson(text);
    final decoded = jsonDecode(quillJson);
    if (decoded is List) {
      return Document.fromJson(decoded.cast<Map<String, dynamic>>());
    }
    return Document();
  }

  String _deltaJson() =>
      jsonEncode(_quillController.document.toDelta().toJson());

  String _plainBody() => _quillController.document.toPlainText().trim();

  bool get _isEmptyNote {
    return _titleController.text.trim().isEmpty && _plainBody().isEmpty;
  }

  String _composeText() {
    if (_isEmptyNote) {
      return '';
    }
    return NoteTextCodec.encodeQuill(
      title: _titleController.text,
      quillDeltaJson: _deltaJson(),
    );
  }

  Future<CloudNote> _ensureNote(BuildContext context) async {
    final widgetNote = context.getArgument<CloudNote>();
    if (widgetNote != null) {
      _note = widgetNote;
      return widgetNote;
    }

    final existingNote = _note;
    if (existingNote != null) {
      return existingNote;
    }
    final user = FirebaseAuthService().currentUser!;
    final userId = user.id;
    final newNote = await _notesService.createNewNote(ownerUserId: userId);
    _note = newNote;
    return newNote;
  }

  Future<void> _flushSave() async {
    final note = _note;
    if (note == null) {
      return;
    }
    final text = _composeText();
    await _notesService.updateNote(documentId: note.documentId, text: text);
    if (mounted) {
      setState(() {
        _isSaving = false;
        _isSaved = true;
      });
    }
  }

  void _scheduleSave() {
    if (_suppressSave) {
      return;
    }
    setState(() {
      _isSaving = true;
      _isSaved = false;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 420), () {
      _flushSave();
    });
  }

  void _onTextChanged() {
    _scheduleSave();
  }

  void _setupTextControllerListener() {
    _titleController.removeListener(_onTextChanged);
    _quillController.removeListener(_onTextChanged);
    _titleController.addListener(_onTextChanged);
    _quillController.addListener(_onTextChanged);
  }

  void _deleteNoteIfTextIsEmpty() {
    final note = _note;
    if (note != null && _composeText().isEmpty) {
      _notesService.deleteNote(documentId: note.documentId);
    }
  }

  Future<void> _saveNoteIfTextIsNotEmpty() async {
    final note = _note;
    final text = _composeText();
    if (note != null && text.isNotEmpty) {
      await _notesService.updateNote(documentId: note.documentId, text: text);
    }
  }

  Future<void> _exit(BuildContext context) async {
    if (_noteFuture != null) {
      try {
        await _noteFuture;
      } catch (_) {}
    }
    if (!context.mounted) {
      return;
    }
    _debounce?.cancel();
    await _flushSave();
    _deleteNoteIfTextIsEmpty();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final note = _note;
    if (note == null) {
      return;
    }
    final label = NoteTextCodec.displayTitle(_composeText());
    final dialogLabel = label == 'Untitled' ? 'this note' : label;
    final shouldDelete = await showDeleteDialog(
      context: context,
      text: dialogLabel,
    );
    if (shouldDelete && context.mounted) {
      await _notesService.deleteNote(documentId: note.documentId);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _noteFuture ??= _ensureNote(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        await _exit(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: BackButton(onPressed: () => _exit(context)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Undo',
                    onPressed: _quillController.hasUndo
                        ? () {
                            _quillController.undo();
                            _scheduleSave();
                          }
                        : null,
                    icon: const Icon(Icons.undo_rounded),
                  ),
                  IconButton(
                    tooltip: 'Redo',
                    onPressed: _quillController.hasRedo
                        ? () {
                            _quillController.redo();
                            _scheduleSave();
                          }
                        : null,
                    icon: const Icon(Icons.redo_rounded),
                  ),
                  if (_isSaving)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text(
                        'Saving…',
                        style: TextStyle(
                          color: MyNotesColors.muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else if (_isSaved)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Row(
                        children: [
                          Text(
                            'Saved',
                            style: TextStyle(
                              color: MyNotesColors.muted,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.check_rounded,
                            color: MyNotesColors.teal,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) async {
                      if (value == 'share') {
                        final encoded = _composeText();
                        if (encoded.isEmpty || _note == null) {
                          await showcannotShareEmptyNoteDialog(
                            context: context,
                          );
                        } else {
                          await SharePlus.instance.share(
                            ShareParams(text: NoteTextCodec.shareText(encoded)),
                          );
                        }
                      } else if (value == 'delete') {
                        await _confirmDelete(context);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'share', child: Text('Share')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(0.5),
            child: Divider(height: 0.5, thickness: 0.5),
          ),
        ),
        body: FutureBuilder<CloudNote>(
          future: _noteFuture,
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(
                    child: Text(
                      'Could not open this note.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  );
                }
                final note = snapshot.data!;
                if (!_listenersAttached) {
                  _suppressSave = true;
                  final decoded = NoteTextCodec.decode(note.text);
                  _titleController.text = decoded.$1;
                  _quillController.dispose();
                  _quillController = QuillController(
                    document: _documentFromStoredText(note.text),
                    selection: const TextSelection.collapsed(offset: 0),
                  );
                  _setupTextControllerListener();
                  _listenersAttached = true;
                  _suppressSave = false;
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: MyNotesColors.divider,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: QuillSimpleToolbar(
                              controller: _quillController,
                              config: QuillSimpleToolbarConfig(
                                multiRowsDisplay: _showExpandedToolbar,
                                showSubscript: false,
                                showSuperscript: false,
                                showSearchButton: false,
                                showUndo: false,
                                showRedo: false,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: _showExpandedToolbar
                                ? 'Collapse toolbar'
                                : 'Show all toolbar options',
                            onPressed: () {
                              setState(() {
                                _showExpandedToolbar = !_showExpandedToolbar;
                              });
                            },
                            icon: Icon(
                              _showExpandedToolbar
                                  ? Icons.arrow_drop_up_rounded
                                  : Icons.arrow_drop_down_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showExpandedToolbar)
                      const Divider(
                        height: 0.5,
                        thickness: 0.5,
                        color: MyNotesColors.divider,
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Hero(
                              tag: NoteCard.heroTagFor(note.documentId),
                              child: Material(
                                color: Colors.transparent,
                                child: TextField(
                                  controller: _titleController,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: MyNotesColors.charcoal,
                                    height: 1.2,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    hintText: 'Title',
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    hintStyle: TextStyle(
                                      color: MyNotesColors.hint,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 28,
                                    ),
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: QuillEditor(
                                controller: _quillController,
                                focusNode: _editorFocus,
                                scrollController: _editorScrollController,
                                config: const QuillEditorConfig(
                                  padding: EdgeInsets.zero,
                                  placeholder:
                                      'Start typing your brilliant idea…',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              default:
                return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}

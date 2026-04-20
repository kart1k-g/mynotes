import 'package:flutter/material.dart';
import 'package:mynotes/features/notes/domain/note_text_codec.dart';
import 'package:mynotes/features/notes/presentation/mynotes_theme.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';

String _relativeTime(DateTime? time) {
  if (time == null) {
    return '';
  }
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inMinutes < 1) {
    return 'Just now';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays}d ago';
  }
  if (diff.inDays < 30) {
    return '${(diff.inDays / 7).floor()}w ago';
  }
  return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
}

class NoteCard extends StatelessWidget {
  const NoteCard({required this.note, required this.onTap, super.key});

  final CloudNote note;
  final VoidCallback onTap;

  static String heroTagFor(String documentId) => 'note-hero-$documentId';

  @override
  Widget build(BuildContext context) {
    final title = NoteTextCodec.displayTitle(note.text);
    final snippet = NoteTextCodec.snippet(note.text);
    final tags = note.tags.isNotEmpty
        ? note.tags
        : NoteTextCodec.hashtags(note.text);
    final hasMedia = NoteTextCodec.hasAttachmentHint(note.text);
    final timeLabel = _relativeTime(note.updatedAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MyNotesColors.cardBorder, width: 0.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Hero(
                        tag: heroTagFor(note.documentId),
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: MyNotesColors.charcoal,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (hasMedia)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.image_outlined,
                          size: 18,
                          color: MyNotesColors.hint,
                        ),
                      ),
                  ],
                ),
                if (snippet.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    snippet,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: MyNotesColors.muted,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (timeLabel.isNotEmpty) ...[
                      const Icon(
                        Icons.schedule_rounded,
                        size: 15,
                        color: MyNotesColors.hint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: MyNotesColors.hint,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (tags.isNotEmpty) ...[
                      const Icon(
                        Icons.sell_outlined,
                        size: 15,
                        color: MyNotesColors.teal,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tags.first,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: MyNotesColors.teal,
                        ),
                      ),
                      if (tags.length > 1)
                        Text(
                          ' +${tags.length - 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: MyNotesColors.hint,
                          ),
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

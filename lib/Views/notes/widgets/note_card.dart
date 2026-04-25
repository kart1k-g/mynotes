import 'package:flutter/material.dart';
import 'package:mynotes/utilites/notes/note_text_codec.dart';
import 'package:mynotes/constants/mynotes_theme.dart';
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
  const NoteCard({
    required this.note,
    required this.onTap,
    required this.tagColors,
    this.isGridView = false,
    this.onTagTap,
    super.key,
  });

  final CloudNote note;
  final VoidCallback onTap;
  final Map<String, int> tagColors;
  final bool isGridView;
  final ValueChanged<String>? onTagTap;

  static const List<Color> _fallbackTagPalette = [
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

  static String heroTagFor(String documentId) => 'note-hero-$documentId';

  Color _colorForTag(String tag) {
    final stored = tagColors[tag.trim().toLowerCase()];
    if (stored != null) {
      return Color(stored);
    }
    return _fallbackTagPalette[tag.hashCode.abs() % _fallbackTagPalette.length];
  }

  Widget _buildTagChip(String tag) {
    final color = _colorForTag(tag);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onTagTap?.call(tag),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 110),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.44), width: 0.7),
        ),
        child: Text(
          '#$tag',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildMoreTagChip(int remaining) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MyNotesColors.pageGrey,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: MyNotesColors.cardBorder, width: 0.7),
      ),
      child: Text(
        '+$remaining',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: MyNotesColors.muted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = NoteTextCodec.displayTitle(note.text);
    final snippet = NoteTextCodec.snippet(note.text);
    final tags = note.tags.isNotEmpty
        ? note.tags
        : NoteTextCodec.hashtags(note.text);
    final displayedTags = tags.take(2).toList();
    final remainingTagCount = tags.length - displayedTags.length;
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
                if (isGridView) ...[
                  if (timeLabel.isNotEmpty)
                    Row(
                      children: [
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
                    ),
                  if (tags.isNotEmpty) ...[
                    if (timeLabel.isNotEmpty) const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in displayedTags) _buildTagChip(tag),
                          if (remainingTagCount > 0)
                            _buildMoreTagChip(remainingTagCount),
                        ],
                      ),
                    ),
                  ],
                ] else
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
                      if (tags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.end,
                          children: [
                            for (final tag in displayedTags) _buildTagChip(tag),
                            if (remainingTagCount > 0)
                              _buildMoreTagChip(remainingTagCount),
                          ],
                        ),
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

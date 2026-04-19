/// Encodes title and body into the single Firestore `text` field using a
/// first-line title convention for new notes. Legacy notes without a newline
/// are treated as body-only.
class NoteTextCodec {
  NoteTextCodec._();

  /// Persists as: `title\nbody` (title is a single line from the UI).
  static String encode({required String title, required String body}) {
    return '$title\n$body';
  }

  /// Decodes persisted text. If there is no newline, the entire string is
  /// body and title is empty.
  static (String title, String body) decode(String text) {
    if (text.isEmpty) {
      return ('', '');
    }
    final i = text.indexOf('\n');
    if (i < 0) {
      return ('', text);
    }
    return (text.substring(0, i), text.substring(i + 1));
  }

  static String displayTitle(String text) {
    final (title, body) = decode(text);
    if (title.trim().isNotEmpty) {
      return title.trim();
    }
    final firstLine = body
        .split('\n')
        .map((e) => e.trim())
        .firstWhere((e) => e.isNotEmpty, orElse: () => '');
    if (firstLine.isEmpty) {
      return 'Untitled';
    }
    return firstLine.length > 56 ? '${firstLine.substring(0, 56)}…' : firstLine;
  }

  static String snippet(String text, {int maxChars = 140}) {
    final (_, body) = decode(text);
    final raw = body.trim().isEmpty ? text.trim() : body.trim();
    if (raw.isEmpty) {
      return '';
    }
    final flat = raw.replaceAll('\n', ' ').trim();
    if (flat.length <= maxChars) {
      return flat;
    }
    return '${flat.substring(0, maxChars).trim()}…';
  }

  /// Lightweight tag hints parsed from body text (no separate DB field).
  static List<String> hashtags(String text) {
    final (_, body) = decode(text);
    final re = RegExp(r'#([a-zA-Z0-9_]+)');
    return re
        .allMatches('$text\n$body')
        .map((m) => m.group(1)!)
        .toSet()
        .take(3)
        .toList();
  }

  static bool hasAttachmentHint(String text) {
    final lower = text.toLowerCase();
    return lower.contains('![') ||
        lower.contains('http://') ||
        lower.contains('https://');
  }
}

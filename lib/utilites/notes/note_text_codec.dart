import 'dart:convert';

/// Stores note content in a Quill-first JSON envelope:
/// {"v":1,"title":"...","delta":[...quill ops...]}
class NoteTextCodec {
  NoteTextCodec._();

  static const List<Map<String, String>> _emptyDelta = [
    {'insert': '\n'},
  ];

  static String encodeQuill({
    required String title,
    required String quillDeltaJson,
  }) {
    final decodedDelta = jsonDecode(quillDeltaJson);
    final delta = decodedDelta is List ? decodedDelta : <dynamic>[];
    return jsonEncode({'v': 1, 'title': title, 'delta': delta});
  }

  static Map<String, dynamic> _decodeEnvelope(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        return <String, dynamic>{'title': '', 'delta': _emptyDelta};
      }
      final titleRaw = decoded['title'];
      final deltaRaw = decoded['delta'];
      if (titleRaw is! String || deltaRaw is! List) {
        return <String, dynamic>{'title': '', 'delta': _emptyDelta};
      }
      return <String, dynamic>{'title': titleRaw, 'delta': deltaRaw};
    } catch (_) {
      return <String, dynamic>{'title': '', 'delta': _emptyDelta};
    }
  }

  /// For editor bootstrap: returns serialized delta JSON array.
  static String decodeQuillDeltaJson(String text) {
    final env = _decodeEnvelope(text);
    return jsonEncode(env['delta']);
  }

  static (String title, String body) decode(String text) {
    final env = _decodeEnvelope(text);
    final title = env['title'] as String;
    final delta = env['delta'] as List;
    final b = StringBuffer();
    for (final op in delta) {
      if (op is! Map) {
        continue;
      }
      final insert = op['insert'];
      if (insert is String) {
        b.write(insert);
      } else if (insert is Map) {
        if (insert.containsKey('image') || insert.containsKey('video')) {
          b.write(' [media] ');
        }
      }
    }
    return (title, b.toString());
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
    final raw = body.trim();
    if (raw.isEmpty) {
      return '';
    }
    final flat = raw.replaceAll('\n', ' ').trim();
    if (flat.length <= maxChars) {
      return flat;
    }
    return '${flat.substring(0, maxChars).trim()}…';
  }

  static String normalizeForSearch(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String searchableText(
    String text, {
    Iterable<String> extraTerms = const [],
  }) {
    final decoded = decode(text);
    final extras = extraTerms.join(' ');
    return normalizeForSearch('${decoded.$1}\n${decoded.$2}\n$extras');
  }

  /// Lightweight tag hints parsed from body text (no separate DB field).
  static List<String> hashtags(String text) {
    final (_, body) = decode(text);
    final re = RegExp(r'#([a-zA-Z0-9_]+)');
    return re.allMatches(body).map((m) => m.group(1)!).toSet().take(3).toList();
  }

  static bool hasAttachmentHint(String text) {
    final delta = jsonDecode(decodeQuillDeltaJson(text));
    if (delta is! List) {
      return false;
    }
    return delta.any((op) {
      if (op is! Map) {
        return false;
      }
      final insert = op['insert'];
      if (insert is Map) {
        return insert.containsKey('image') || insert.containsKey('video');
      }
      if (insert is String) {
        final lower = insert.toLowerCase();
        return lower.contains('http://') || lower.contains('https://');
      }
      return false;
    });
  }

  /// Human-friendly note text for sharing.
  static String shareText(String text) {
    final (title, bodyRaw) = decode(text);
    final body = bodyRaw.trim();
    if (title.trim().isEmpty) {
      return body;
    }
    if (body.isEmpty) {
      return title.trim();
    }
    return '${title.trim()}\n\n$body';
  }
}
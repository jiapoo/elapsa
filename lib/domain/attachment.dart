import 'dart:convert';

/// Something kept alongside a document that is not a picture of it.
///
/// A renewal is rarely just the card: there is the PDF of the application, the
/// receipt from the embassy, the page on the government site where the form
/// lives. Those belong with the document they are about, not scattered across
/// Files and a browser's history.
enum AttachmentKind {
  /// A file whose bytes Elapsa keeps, encrypted, beside the document's photos.
  file,

  /// A web address. Only the address is stored; nothing is fetched.
  link,
}

class Attachment {
  const Attachment({
    required this.id,
    required this.kind,
    required this.name,
    required this.addedAt,
    this.url,
    this.size,
  });

  final String id;
  final AttachmentKind kind;

  /// What the user sees: the file's own name, or the link's title.
  final String name;

  /// The address, for a link. Null for a file.
  final String? url;

  /// Bytes on disk before encryption, for a file.
  final int? size;

  final DateTime addedAt;

  /// The lower-case extension of a file's name, without the dot.
  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'name': name,
    if (url != null) 'url': url,
    if (size != null) 'size': size,
    'addedAt': addedAt.toIso8601String(),
  };

  /// Null for anything malformed, so one bad entry cannot take the list down.
  static Attachment? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final name = raw['name'];
    final kind = AttachmentKind.values
        .where((k) => k.name == raw['kind'])
        .firstOrNull;
    if (id is! String || name is! String || kind == null) return null;
    final url = raw['url'];
    if (kind == AttachmentKind.link && url is! String) return null;

    return Attachment(
      id: id,
      kind: kind,
      name: name,
      url: url is String ? url : null,
      size: (raw['size'] as num?)?.toInt(),
      addedAt:
          DateTime.tryParse(raw['addedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static List<Attachment> decodeList(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final raw = jsonDecode(json);
      if (raw is! List) return const [];
      return raw.map(fromJson).whereType<Attachment>().toList();
    } on FormatException {
      return const [];
    }
  }

  static String? encodeList(List<Attachment> attachments) => attachments.isEmpty
      ? null
      : jsonEncode([for (final a in attachments) a.toJson()]);

  /// Turns what someone typed into an address a browser can open, or null.
  ///
  /// "gov.uk/renew-passport" is how people write addresses, so a missing
  /// scheme is supplied rather than refused. Anything that is not http(s)
  /// afterwards is refused: a link here is a web page, and a `tel:` or
  /// `javascript:` dressed up as one is not something to open on a tap.
  static Uri? normaliseUrl(String input) {
    var text = input.trim();
    if (text.isEmpty || text.contains(' ')) return null;
    if (!text.contains('://')) text = 'https://$text';
    final uri = Uri.tryParse(text);
    if (uri == null) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    if (uri.host.isEmpty || !uri.host.contains('.')) return null;
    return uri;
  }
}

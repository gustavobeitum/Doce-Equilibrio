import 'dart:convert';

class NotificationPayload {
  final int reminderId;
  final String title;
  final String type;

  const NotificationPayload({
    required this.reminderId,
    required this.title,
    required this.type,
  });

  String encode() {
    return jsonEncode({
      'lembreteId': reminderId,
      'titulo': title,
      'tipo': type,
    });
  }

  static NotificationPayload? tryParse(String? payload) {
    if (payload == null) return null;
    try {
      final map = jsonDecode(payload);
      if (map is! Map<String, dynamic>) return null;

      final reminderId = map['lembreteId'];
      final title = map['titulo'];
      final type = map['tipo'];
      if (reminderId is! int || title is! String || type is! String) {
        return null;
      }

      return NotificationPayload(
        reminderId: reminderId,
        title: title,
        type: type,
      );
    } catch (_) {
      return null;
    }
  }
}

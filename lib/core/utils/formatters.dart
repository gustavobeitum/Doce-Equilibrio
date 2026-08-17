/// Formatadores de data/hora reutilizáveis entre telas e widgets.
class Formatters {
  Formatters._();

  static String date(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static String time(DateTime date) {
    final time = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$time:$minute';
  }

  static String dateTime(DateTime date) {
    return '${Formatters.date(date)} às ${Formatters.time(date)}';
  }
}

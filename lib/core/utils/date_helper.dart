import 'package:intl/intl.dart';

class DateHelper {
  static String formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  static String toIsoDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

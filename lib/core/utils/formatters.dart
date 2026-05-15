import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
  static final _currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
  static final _percentFormat = NumberFormat.percentPattern('fr_FR');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  static String formatCurrency(double amount) => _currencyFormat.format(amount);
  static String formatPercent(double value) => _percentFormat.format(value);

  static String formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
  }
}

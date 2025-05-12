class FormatUtils {
  /// Formats a weight value to a string with 1 decimal place when needed
  static String formatWeight(double weight) {
    if (weight == weight.roundToDouble()) {
      return weight.toInt().toString();
    } else {
      return weight.toStringAsFixed(1);
    }
  }

  /// Formats a DateTime to a human-readable string (e.g., "May 12, 2025")
  static String formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Formats a DateTime to a short format (e.g., "05/12/25")
  static String formatShortDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
  }
}

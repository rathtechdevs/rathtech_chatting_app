import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String toMessageTime() => DateFormat.jm().format(toLocal());

  String toDateSeparator() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(year, month, day);

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    if (now.difference(this).inDays < 7) return DateFormat.EEEE().format(this);
    return DateFormat.yMMMd().format(this);
  }

  String toLastSeen() {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return DateFormat.EEEE().format(this);
    return DateFormat.yMMMd().format(this);
  }

  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

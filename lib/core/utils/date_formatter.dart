import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class AppDateFormatter {
  /// Format chat list timestamp:
  /// Today: "10:30"
  /// Yesterday: "Yesterday"
  /// This week: "Wednesday"
  /// Older: "23/09/2026"
  static String formatChatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final difference = today.difference(messageDate).inDays;

    if (difference == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  /// Format inside message bubble: "10:30"
  static String formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Format last seen: "last seen today at 10:30" or "last seen 5 minutes ago"
  static String formatLastSeen(DateTime? lastSeen, bool isOnline) {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Offline';
    return 'Last seen ${timeago.format(lastSeen)}';
  }
}

/// Time Utilities
/// 
/// Single Responsibility: Handle timezone conversions and formatting for Indian Standard Time (IST)
/// IST is UTC+5:30
/// 
/// IMPORTANT: Server stores all times in UTC. When displaying to users, we convert to IST.
/// This ensures all users see the same time regardless of their phone's timezone setting.

import 'package:intl/intl.dart';

class TimeUtils {
  /// IST timezone offset: UTC+5:30 (5 hours 30 minutes)
  static const Duration istOffset = Duration(hours: 5, minutes: 30);

  /// Get current time in IST
  /// Returns a DateTime object representing current time in IST
  static DateTime getCurrentIST() {
    final now = DateTime.now().toUtc();
    // Add IST offset to UTC time
    return now.add(istOffset);
  }

  /// Convert UTC DateTime to IST for display
  /// Takes a UTC DateTime (from server) and returns a DateTime adjusted to IST
  /// This is used for formatting - the DateTime represents IST time
  static DateTime toIST(DateTime dateTime) {
    // Ensure we're working with UTC
    final utc = dateTime.isUtc ? dateTime : dateTime.toUtc();
    // Add IST offset (UTC+5:30)
    return utc.add(istOffset);
  }

  /// Format DateTime in IST
  /// Server sends UTC, this converts to IST and formats for display
  /// Format: "dd MMM yyyy, hh:mm a" (e.g., "27 Dec 2024, 03:30 PM")
  static String formatIST(DateTime dateTime) {
    final istTime = toIST(dateTime);
    return DateFormat('dd MMM yyyy, hh:mm a').format(istTime);
  }

  /// Format DateTime in IST with timezone indicator
  /// Format: "dd MMM yyyy, hh:mm a IST"
  static String formatISTWithZone(DateTime dateTime) {
    final istTime = toIST(dateTime);
    return DateFormat('dd MMM yyyy, hh:mm a \'IST\'').format(istTime);
  }

  /// Format date only in IST
  /// Format: "dd MMM yyyy" (e.g., "27 Dec 2024")
  static String formatISTDateOnly(DateTime dateTime) {
    final istTime = toIST(dateTime);
    return DateFormat('dd MMM yyyy').format(istTime);
  }

  /// Format time only in IST
  /// Format: "hh:mm a IST" (e.g., "03:30 PM IST")
  static String formatISTTimeOnly(DateTime dateTime) {
    final istTime = toIST(dateTime);
    return DateFormat('hh:mm a \'IST\'').format(istTime);
  }

  /// Format date in short format for lists
  /// Format: "dd MMM, hh:mm a" (e.g., "27 Dec, 03:30 PM")
  static String formatISTShort(DateTime dateTime) {
    final istTime = toIST(dateTime);
    return DateFormat('dd MMM, hh:mm a').format(istTime);
  }

  /// Format time for chat list (WhatsApp-style)
  /// Returns "Today", "Yesterday", or date like "27 Dec"
  static String formatChatListTime(DateTime dateTime) {
    final istTime = toIST(dateTime);
    final now = getCurrentIST();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(istTime.year, istTime.month, istTime.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (messageDate == today) {
      // Today - show time only
      return DateFormat('hh:mm a').format(istTime);
    } else if (messageDate == yesterday) {
      // Yesterday
      return 'Yesterday';
    } else {
      // Older - show date
      return DateFormat('dd/MM/yy').format(istTime);
    }
  }

  /// Format time for chat messages (WhatsApp-style)
  /// Returns time like "10:30 AM" or "Yesterday 10:30 AM" or "27 Dec 10:30 AM"
  static String formatChatMessageTime(DateTime dateTime) {
    final istTime = toIST(dateTime);
    final now = getCurrentIST();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(istTime.year, istTime.month, istTime.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final timeStr = DateFormat('hh:mm a').format(istTime);

    if (messageDate == today) {
      return timeStr;
    } else if (messageDate == yesterday) {
      return 'Yesterday $timeStr';
    } else {
      return DateFormat('dd MMM, $timeStr').format(istTime);
    }
  }

  /// Check if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    final d1 = DateTime(date1.year, date1.month, date1.day);
    final d2 = DateTime(date2.year, date2.month, date2.day);
    return d1 == d2;
  }

  /// Get date separator text for chat messages
  /// Returns "Today", "Yesterday", or formatted date
  static String getDateSeparator(DateTime dateTime) {
    final istTime = toIST(dateTime);
    final now = getCurrentIST();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(istTime.year, istTime.month, istTime.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('dd MMMM yyyy').format(istTime);
    }
  }
}


class PhoneNumberFormatter {
  /// Converts any Indonesian or international phone number to clean E.164 format.
  /// Example: "0812-3456-7890" -> "+6281234567890"
  /// Example: "628123456789" -> "+628123456789"
  /// Example: "+62 812 3456" -> "+628123456"
  static String toE164(String rawNumber, {String defaultCountryCode = '+62'}) {
    // Strip non-digit characters except leading +
    String cleaned = rawNumber.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');

    if (cleaned.startsWith('+')) {
      return cleaned;
    } else if (cleaned.startsWith('62')) {
      return '+$cleaned';
    } else if (cleaned.startsWith('0')) {
      return '$defaultCountryCode${cleaned.substring(1)}';
    } else {
      return '$defaultCountryCode$cleaned';
    }
  }

  /// Formats for display: "+62 812-3456-7890"
  static String toDisplay(String e164Number) {
    if (!e164Number.startsWith('+62')) return e164Number;
    final clean = e164Number.replaceAll('+62', '0');
    if (clean.length < 8) return e164Number;
    return '+62 ${clean.substring(1, 4)}-${clean.substring(4, 8)}-${clean.substring(8)}';
  }

  /// Checks whether a normalized phone number is valid
  static bool isValid(String rawNumber) {
    final cleaned = rawNumber.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    return RegExp(r'^\+?[0-9]{8,15}$').hasMatch(cleaned);
  }
}

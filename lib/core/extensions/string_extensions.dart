extension StringExtensions on String {
  bool get isValidEmail {
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(trim());
  }

  bool get isValidPhone {
    final regex = RegExp(r'^\+[1-9]\d{7,14}$');
    return regex.hasMatch(trim().replaceAll(' ', ''));
  }

  bool get isBlank => trim().isEmpty;

  String get initials {
    final parts = trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String truncate(int maxLength, {String ellipsis = '…'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }
}

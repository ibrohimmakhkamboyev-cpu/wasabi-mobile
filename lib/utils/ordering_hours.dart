const _requiredStart = 11 * 60;
const _requiredEnd = 23 * 60;

/// The restaurant accepts new orders from 11:00 up to, but not including,
/// 23:00 in Tashkent time. Settings may narrow this window but never extend it.
class OrderingHours {
  const OrderingHours._(this.startMinutes, this.endMinutes);

  final int startMinutes;
  final int endMinutes;

  factory OrderingHours.fromSettings({
    required String workStart,
    required String workEnd,
  }) {
    final configuredStart = _parseMinutes(workStart) ?? _requiredStart;
    final configuredEnd = _parseMinutes(workEnd) ?? _requiredEnd;
    return OrderingHours._(
      configuredStart < _requiredStart ? _requiredStart : configuredStart,
      configuredEnd > _requiredEnd ? _requiredEnd : configuredEnd,
    );
  }

  bool isOpenAt(DateTime now) {
    final tashkent = now.toUtc().add(const Duration(hours: 5));
    final minutes = tashkent.hour * 60 + tashkent.minute;
    return startMinutes < endMinutes &&
        minutes >= startMinutes &&
        minutes < endMinutes;
  }

  String get startLabel => _format(startMinutes);
  String get endLabel => _format(endMinutes);

  static int? _parseMinutes(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return null;
    }
    return hour * 60 + minute;
  }

  static String _format(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';
}

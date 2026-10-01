import 'package:flutter_test/flutter_test.dart';
import 'package:wasabi_mobile/utils/ordering_hours.dart';

void main() {
  final hours = OrderingHours.fromSettings(
    workStart: '10:00',
    workEnd: '23:30',
  );

  test('enforces the 11:00–23:00 Tashkent ordering window', () {
    expect(hours.startLabel, '11:00');
    expect(hours.endLabel, '23:00');
    expect(hours.isOpenAt(DateTime.utc(2026, 9, 25, 5, 59)), isFalse);
    expect(hours.isOpenAt(DateTime.utc(2026, 9, 25, 6, 0)), isTrue);
    expect(hours.isOpenAt(DateTime.utc(2026, 9, 25, 17, 59)), isTrue);
    expect(hours.isOpenAt(DateTime.utc(2026, 9, 25, 18, 0)), isFalse);
  });

  test('allows settings to shorten but not expand order hours', () {
    final narrowed = OrderingHours.fromSettings(
      workStart: '12:00',
      workEnd: '22:00',
    );
    expect(narrowed.startLabel, '12:00');
    expect(narrowed.endLabel, '22:00');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:albmap/features/map/domain/business_open_status.dart';

void main() {
  // A Wednesday, so weekday-key math (DateTime.weekday 1..7 -> Mon..Sun)
  // has a fixed, known day to test against.
  DateTime wed(int hour, int minute) => DateTime(2026, 8, 5, hour, minute); // Aug 5 2026 is a Wednesday

  group('businessOpenStatus', () {
    test('no hours entered at all -> unknown, not closed', () {
      expect(businessOpenStatus(const {}, now: wed(12, 0)), BusinessOpenStatus.unknown);
    });

    test('hours exist for other days but not today -> closed', () {
      final hours = {'Mon': '09:00-17:00', 'Fri': '09:00-17:00'};
      expect(businessOpenStatus(hours, now: wed(12, 0)), BusinessOpenStatus.closed);
    });

    test('within today\'s normal (same-day) range -> open', () {
      final hours = {'Wed': '09:00-18:00'};
      expect(businessOpenStatus(hours, now: wed(12, 0)), BusinessOpenStatus.open);
    });

    test('before opening -> closed', () {
      final hours = {'Wed': '09:00-18:00'};
      expect(businessOpenStatus(hours, now: wed(8, 59)), BusinessOpenStatus.closed);
    });

    test('at the exact opening minute -> open (inclusive start)', () {
      final hours = {'Wed': '09:00-18:00'};
      expect(businessOpenStatus(hours, now: wed(9, 0)), BusinessOpenStatus.open);
    });

    test('at the exact closing minute -> closed (exclusive end)', () {
      final hours = {'Wed': '09:00-18:00'};
      expect(businessOpenStatus(hours, now: wed(18, 0)), BusinessOpenStatus.closed);
    });

    test('after closing -> closed', () {
      final hours = {'Wed': '09:00-18:00'};
      expect(businessOpenStatus(hours, now: wed(18, 1)), BusinessOpenStatus.closed);
    });

    // Overnight ranges (e.g. a bar/club open 20:00-02:00) wrap past
    // midnight — this is the case a naive "open <= now < close" check
    // gets wrong, since close (02:00) is numerically before open (20:00).
    test('overnight range: open in the evening before midnight -> open', () {
      final hours = {'Wed': '20:00-02:00'};
      expect(businessOpenStatus(hours, now: wed(23, 30)), BusinessOpenStatus.open);
    });

    test('overnight range: open just after midnight, before close -> open', () {
      final hours = {'Wed': '20:00-02:00'};
      expect(businessOpenStatus(hours, now: wed(1, 30)), BusinessOpenStatus.open);
    });

    test('overnight range: mid-afternoon, well outside the range -> closed', () {
      final hours = {'Wed': '20:00-02:00'};
      expect(businessOpenStatus(hours, now: wed(14, 0)), BusinessOpenStatus.closed);
    });

    test('malformed stored range -> closed, not a crash', () {
      final hours = {'Wed': 'garbage'};
      expect(businessOpenStatus(hours, now: wed(12, 0)), BusinessOpenStatus.closed);
    });
  });
}

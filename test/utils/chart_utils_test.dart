import 'package:flutter_test/flutter_test.dart';

import 'package:realoptions/models/response.dart';
import 'package:realoptions/utils/chart_utils.dart';

void main() {
  group('getAxis', () {
    test('spreads ticks evenly and includes both endpoints', () {
      final axis = getAxis(1.0, 5.0);
      expect(axis.length, NUM_TICKS);
      expect(axis[0], 1.0);
      expect(axis[1], 2.0);
      expect(axis[2], 3.0);
      expect(axis[3], 4.0);
      expect(axis[4], 5.0);
    });

    test('honours a custom tick count', () {
      final axis = getAxis(0.0, 1.0, ticks: 3);
      expect(axis, [0.0, 0.5, 1.0]);
    });

    test('a degenerate range yields a single tick rather than a zero step', () {
      final axis = getAxis(2.0, 2.0, ticks: 1);
      expect(axis, [2.0]);
    });
  });

  group('AxisRange', () {
    test('interval matches the spacing between consecutive values', () {
      const range = AxisRange(0, 10, ticks: 5);
      expect(range.interval, 2.5);
      for (var i = 1; i < range.values.length; i++) {
        expect(range.values[i] - range.values[i - 1], closeTo(range.interval, 1e-12));
      }
    });

    test('a single-value range reports a zero interval', () {
      const range = AxisRange(3, 3, ticks: 1);
      expect(range.interval, 0.0);
    });
  });

  group('domain', () {
    test('spans the first to the last at_point', () {
      final results = [
        ModelResult(value: 1, atPoint: 90),
        ModelResult(value: 2, atPoint: 100),
        ModelResult(value: 3, atPoint: 110),
      ];
      final domain = getDomain(results);
      expect(domain.min, 90.0);
      expect(domain.max, 110.0);
    });

    test('an empty result set does not throw', () {
      expect(getDomain([]).max, greaterThan(getDomain([]).min));
    });
  });

  group('implied volatility range', () {
    test('pads both ends by PADDING_PERCENTAGE', () {
      final results = [
        ModelResult(value: 1, atPoint: 1, iv: 0.20),
        ModelResult(value: 2, atPoint: 2, iv: 0.40),
      ];
      final range = getIVRange(results);
      expect(range.min, closeTo(0.20 * (1 - PADDING_PERCENTAGE), 1e-12));
      expect(range.max, closeTo(0.40 * (1 + PADDING_PERCENTAGE), 1e-12));
    });

    test('missing iv values are dropped rather than poisoning the range', () {
      final results = [
        ModelResult(value: 1, atPoint: 1, iv: 0.20),
        ModelResult(value: 2, atPoint: 2),
        ModelResult(value: 3, atPoint: 3, iv: 0.30),
      ];
      final range = getIVRange(results);
      expect(range.min, closeTo(0.20 * (1 - PADDING_PERCENTAGE), 1e-12));
      expect(range.max, closeTo(0.30 * (1 + PADDING_PERCENTAGE), 1e-12));
    });

    test('a set with no iv at all falls back to a usable range', () {
      final results = [ModelResult(value: 1, atPoint: 1)];
      final range = getIVRange(results);
      expect(range.min, 0.0);
      expect(range.max, 1.0);
    });
  });

  group('density range', () {
    test('is pinned at zero and padded above the peak', () {
      final results = [
        ModelResult(value: 0.5, atPoint: 1),
        ModelResult(value: 2.0, atPoint: 2),
        ModelResult(value: 1.0, atPoint: 3),
      ];
      final range = getDensityRange(results);
      expect(range.min, 0.0);
      expect(range.max, closeTo(2.0 * (1 + PADDING_PERCENTAGE), 1e-12));
    });
  });

  group('toSpots', () {
    test('maps at_point to x and the selector to y', () {
      final results = [
        ModelResult(value: 7, atPoint: 3, iv: 0.25),
        ModelResult(value: 8, atPoint: 4, iv: 0.35),
      ];
      final spots = toSpots(results, (r) => r.value.toDouble());
      expect(spots.map((s) => s.x).toList(), [3.0, 4.0]);
      expect(spots.map((s) => s.y).toList(), [7.0, 8.0]);

      final ivSpots = toSpots(results, (r) => r.iv!.toDouble());
      expect(ivSpots.map((s) => s.y).toList(), [0.25, 0.35]);
    });
  });
}

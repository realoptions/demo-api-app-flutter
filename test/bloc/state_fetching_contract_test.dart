import 'package:flutter_test/flutter_test.dart';

import 'package:realoptions/blocs/density/density_state.dart';
import 'package:realoptions/blocs/options/options_state.dart';
import 'package:realoptions/models/response.dart';

/// The `isFetching` contract the submit button depends on.
///
/// The button used to ask `densityData is IsDensityFetching` directly. It now
/// asks the state, so the decision "does this state count as busy" lives with
/// the state rather than at each call site. This table is that decision made
/// explicit.
///
/// What makes it safe to move is that the getter is an exhaustive switch over a
/// sealed hierarchy: a new state cannot be added without saying here whether it
/// is busy, so the answer cannot silently default to the wrong one.
void main() {
  final DensityAndVaR density = DensityAndVaR(
    density: [ModelResult(value: 1, atPoint: 1)],
    riskMetrics: VaRResult(valueAtRisk: 0.1, expectedShortfall: 0.2),
  );
  final OptionPrices prices = OptionPrices(
    calls: [ModelResult(value: 1, atPoint: 1)],
    puts: [ModelResult(value: 2, atPoint: 2)],
  );

  group('DensityState.isFetching', () {
    test('the in-flight state is busy', () {
      expect(IsDensityFetching().isFetching, isTrue);
    });

    test('every settled state is not busy', () {
      expect(DensityNoData().isFetching, isFalse);
      expect(DensityError(densityError: 'boom').isFetching, isFalse);
      expect(DensityData(density: density).isFetching, isFalse);
    });
  });

  group('OptionsState.isFetching', () {
    test('the in-flight state is busy', () {
      expect(IsOptionsFetching().isFetching, isTrue);
    });

    test('every settled state is not busy', () {
      expect(OptionsNoData().isFetching, isFalse);
      expect(OptionsError(optionsError: 'boom').isFetching, isFalse);
      expect(OptionsData(options: prices).isFetching, isFalse);
    });
  });
}

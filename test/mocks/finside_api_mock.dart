import 'package:mockito/mockito.dart';
import 'package:realoptions/models/api_request.dart';
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/models/response.dart';
import 'package:realoptions/services/finside_service.dart';

/// Shared hand-written mock of [FinsideApi].
///
/// The calculation methods take a non-nullable [CalculationRequest] now, which
/// a bare `extends Mock implements FinsideApi` cannot cope with under sound null
/// safety: mockito's `any` matcher is typed `Null`, so it could not be passed
/// to a non-nullable parameter, and `noSuchMethod` hands back `null` while a
/// stub is being recorded, which cannot satisfy a `Future<T>` return type.
///
/// So each stubbed method is written out with the parameter widened to nullable
/// (a legal contravariant override — the production signature stays
/// non-nullable) and a typed `returnValue` for the recording phase.
/// [throwOnMissingStub] keeps an unstubbed call loud rather than silently
/// handing back the placeholder.
///
/// Tests stub over the placeholders; the placeholder values are never asserted.
class MockFinsideService extends Mock implements FinsideApi {
  MockFinsideService() {
    throwOnMissingStub(this);
  }

  static final DensityAndVaR _placeholderDensity = DensityAndVaR(
    density: const <ModelResult>[],
    riskMetrics: VaRResult(valueAtRisk: 0.0, expectedShortfall: 0.0),
  );

  static const OptionPrices _placeholderPrices =
      OptionPrices(calls: <ModelResult>[], puts: <ModelResult>[]);

  static const List<InputConstraint> _placeholderConstraints =
      <InputConstraint>[];

  @override
  Future<List<InputConstraint>> fetchConstraints(String? model) =>
      super.noSuchMethod(Invocation.method(#fetchConstraints, [model]),
              returnValue:
                  Future<List<InputConstraint>>.value(_placeholderConstraints))
          as Future<List<InputConstraint>>;

  @override
  Future<DensityAndVaR> fetchDensityAndVaR(CalculationRequest? request) =>
      super.noSuchMethod(Invocation.method(#fetchDensityAndVaR, [request]),
              returnValue: Future<DensityAndVaR>.value(_placeholderDensity))
          as Future<DensityAndVaR>;

  @override
  Future<OptionPrices> fetchOptionPrices(CalculationRequest? request) =>
      super.noSuchMethod(Invocation.method(#fetchOptionPrices, [request]),
              returnValue: Future<OptionPrices>.value(_placeholderPrices))
          as Future<OptionPrices>;
}

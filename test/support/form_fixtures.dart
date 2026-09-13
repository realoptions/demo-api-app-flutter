import 'package:realoptions/models/api_request.dart';
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/models/models.dart';

const Model heston = Model(label: "Heston", value: "heston");

/// A complete, internally consistent Heston submission: the five market
/// fields plus the five parameters Heston defines.
///
/// Fresh instance per call — several tests mutate a copy of this to remove or
/// add a field, and a shared const map would make them interfere.
Map<String, SubmitItems> fullHestonForm() => {
      "asset": SubmitItems(value: 4.0, inputType: InputType.Market),
      "maturity": SubmitItems(value: 1.0, inputType: InputType.Market),
      "num_u": SubmitItems(value: 8, inputType: InputType.Market),
      "quantile": SubmitItems(value: 0.05, inputType: InputType.Market),
      "rate": SubmitItems(value: 0.04, inputType: InputType.Market),
      "v0": SubmitItems(value: 0.3, inputType: InputType.Model),
      "speed": SubmitItems(value: 1.5, inputType: InputType.Model),
      "eta_v": SubmitItems(value: 1.5, inputType: InputType.Model),
      "sigma": SubmitItems(value: 0.35, inputType: InputType.Model),
      "rho": SubmitItems(value: -0.2, inputType: InputType.Model),
    };

/// The request the app would build from [fullHestonForm].
///
/// Built through the real `toRequest` mapping rather than hand-rolled, so a
/// test written against this object exercises the same path the submit button
/// takes — including the market/cf split.
CalculationRequest hestonRequest() =>
    SubmitBody(model: heston, formBody: fullHestonForm()).toRequest();

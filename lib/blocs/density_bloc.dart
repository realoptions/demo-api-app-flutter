import 'package:demo_api_app_flutter/blocs/bloc_provider.dart' as bloc_provider;
import 'dart:async';
import 'package:demo_api_app_flutter/services/api_consume.dart';
import 'package:demo_api_app_flutter/models/response.dart';
import 'package:demo_api_app_flutter/models/forms.dart';
import 'package:demo_api_app_flutter/utils/services.dart';
import 'package:rxdart/rxdart.dart';

class DensityBloc implements bloc_provider.BlocBase {
  StreamController<List<ModelResult>> _densityController = BehaviorSubject();

  Stream<List<ModelResult>> get outDensityResults => _densityController.stream;

  DensityBloc();

  void getDensity(
      String model, String apiKey, Map<String, SubmitItems> submittedBody) {
    var body = convertSubmission(submittedBody, generateStrikes);

    fetchModelDensity(model, apiKey, body).then((results) {
      _densityController.sink.add(results.results);
    });
  }

  void dispose() {
    _densityController.close();
  }
}

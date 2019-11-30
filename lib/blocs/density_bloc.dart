import 'package:demo_api_app_flutter/blocs/bloc_provider.dart' as bloc_provider;
import 'dart:async';
import 'package:demo_api_app_flutter/services/api_consume.dart';
import 'package:demo_api_app_flutter/models/response.dart';
import 'package:demo_api_app_flutter/models/forms.dart';
import 'package:demo_api_app_flutter/utils/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:demo_api_app_flutter/models/progress.dart';

class DensityBloc implements bloc_provider.BlocBase {
  StreamController<ModelResults> _densityController = BehaviorSubject();
  StreamController<StreamProgress> _connectionController = BehaviorSubject();

  Stream<ModelResults> get outDensityResults => _densityController.stream;
  Stream<StreamProgress> get outDensityProgress => _connectionController.stream;
  StreamSink get inDensityProgress => _connectionController.sink;
  DensityBloc() {
    inDensityProgress.add(StreamProgress.NoData);
  }

  void getDensity(
      String model, String apiKey, Map<String, SubmitItems> submittedBody) {
    var body = convertSubmission(submittedBody, generateStrikes);
    inDensityProgress.add(StreamProgress.Busy);
    fetchModelDensity(model, apiKey, body).then((result) {
      _densityController.sink.add(result);
      inDensityProgress.add(StreamProgress.DataRetrieved);
    }).catchError(_densityController.addError);
  }

  void dispose() {
    _densityController.close();
    _connectionController.close();
  }
}
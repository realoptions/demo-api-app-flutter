import 'package:demo_api_app_flutter/blocs/bloc_provider.dart' as bloc_provider;
import 'dart:async';
import 'package:demo_api_app_flutter/services/finside_service.dart';
import 'package:demo_api_app_flutter/models/response.dart';
import 'package:demo_api_app_flutter/models/forms.dart';
import 'package:demo_api_app_flutter/utils/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:demo_api_app_flutter/models/progress.dart';

class OptionsBloc implements bloc_provider.BlocBase {
  final StreamController<Map<String, List<ModelResult>>> _optionController =
      BehaviorSubject();

  final StreamController<StreamProgress> _connectionController =
      BehaviorSubject();

  Stream<Map<String, List<ModelResult>>> get outOptionResults =>
      _optionController.stream;
  Stream<StreamProgress> get outOptionsProgress => _connectionController.stream;
  StreamSink get inOptionsProgress => _connectionController.sink;

  OptionsBloc() {
    inOptionsProgress.add(StreamProgress.NoData);
  }

  Future<void> getOptionPrices(
      String model, String apiKey, Map<String, SubmitItems> submittedBody) {
    var body = convertSubmission(submittedBody, generateStrikes);
    inOptionsProgress.add(StreamProgress.Busy);
    return fetchOptionPrices(model, apiKey, body).then((result) {
      _optionController.sink.add(result);
      inOptionsProgress.add(StreamProgress.DataRetrieved);
    }).catchError(_connectionController.addError);
  }

  void dispose() {
    _optionController.close();
    _connectionController.close();
  }
}

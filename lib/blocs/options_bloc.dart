import 'package:demo_api_app_flutter/blocs/bloc_provider.dart' as bloc_provider;
import 'dart:async';
import 'package:demo_api_app_flutter/services/finside_service.dart';
import 'package:demo_api_app_flutter/models/response.dart';
import 'package:demo_api_app_flutter/models/forms.dart';
import 'package:rxdart/rxdart.dart';
import 'package:demo_api_app_flutter/models/progress.dart';
import 'package:meta/meta.dart';

class OptionsBloc implements bloc_provider.BlocBase {
  final StreamController<Map<String, List<ModelResult>>> _optionController =
      BehaviorSubject();

  final StreamController<StreamProgress> _connectionController =
      BehaviorSubject();
  final FinsideApi finside;
  Stream<Map<String, List<ModelResult>>> get outOptionResults =>
      _optionController.stream;
  Stream<StreamProgress> get outOptionsProgress => _connectionController.stream;
  StreamSink get inOptionsProgress => _connectionController.sink;

  OptionsBloc({@required this.finside}) {
    inOptionsProgress.add(StreamProgress.NoData);
  }

  Future<void> getOptionPrices(Map<String, SubmitItems> submittedBody) {
    SubmitBody body = SubmitBody(formBody: submittedBody);
    inOptionsProgress.add(StreamProgress.Busy);
    return finside.fetchOptionPrices(body.convertSubmission()).then((result) {
      _optionController.sink.add(result);
      inOptionsProgress.add(StreamProgress.DataRetrieved);
    }).catchError(_connectionController.addError);
  }

  void dispose() {
    _optionController.close();
    _connectionController.close();
  }
}

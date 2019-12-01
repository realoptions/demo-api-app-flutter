import 'package:demo_api_app_flutter/blocs/bloc_provider.dart' as bloc_provider;
import 'dart:async';
import 'package:demo_api_app_flutter/services/finside_service.dart';
import 'package:demo_api_app_flutter/models/response.dart';
import 'package:demo_api_app_flutter/models/forms.dart';
import 'package:demo_api_app_flutter/utils/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:demo_api_app_flutter/models/progress.dart';
import 'package:meta/meta.dart';
class DensityBloc implements bloc_provider.BlocBase {
  final StreamController<List<ModelResult>> _densityController =
      BehaviorSubject();
  final StreamController<StreamProgress> _connectionController =
      BehaviorSubject();
  final FinsideApi finside;
  Stream<List<ModelResult>> get outDensityResults => _densityController.stream;
  Stream<StreamProgress> get outDensityProgress => _connectionController.stream;
  StreamSink get inDensityProgress => _connectionController.sink;
  DensityBloc({@required this.finside}) {
    inDensityProgress.add(StreamProgress.NoData);
  }

  Future<void> getDensity(Map<String, SubmitItems> submittedBody) {
    var body = convertSubmission(submittedBody, generateStrikes);
    inDensityProgress.add(StreamProgress.Busy);
    return finside.fetchModelDensity(body).then((result) {
      _densityController.sink.add(result);
      inDensityProgress.add(StreamProgress.DataRetrieved);
    }).catchError(_connectionController.addError);
  }

  void dispose() {
    _densityController.close();
    _connectionController.close();
  }
}

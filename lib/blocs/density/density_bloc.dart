import 'package:realoptions/blocs/bloc_provider.dart' as bloc_provider;
import 'dart:async';
import 'package:realoptions/services/finside_service.dart';
import 'package:realoptions/models/response.dart';
import 'package:realoptions/models/forms.dart';
import 'package:rxdart/rxdart.dart';
import 'package:realoptions/models/progress.dart';
import 'package:meta/meta.dart';

class DensityBloc implements bloc_provider.BlocBase {
  final StreamController<DensityAndVaR> _densityController = BehaviorSubject();
  final StreamController<StreamProgress> _connectionController =
      BehaviorSubject();
  final FinsideApi finside;
  Stream<DensityAndVaR> get outDensityController => _densityController.stream;
  StreamSink get _inDensityController => _densityController.sink;

  Stream<StreamProgress> get outDensityProgress => _connectionController.stream;
  StreamSink get inDensityProgress => _connectionController.sink;

  DensityBloc({@required this.finside}) {
    inDensityProgress.add(StreamProgress.NoData);
  }

  Future<void> getDensity(Map<String, SubmitItems> submittedBody) {
    SubmitBody body = SubmitBody(formBody: submittedBody);
    inDensityProgress.add(StreamProgress.Busy);
    return finside.fetchDensityAndVaR(body.convertSubmission()).then((result) {
      _inDensityController.add(result);
      inDensityProgress.add(StreamProgress.DataRetrieved);
    }).catchError((error) {
      _inDensityController.addError(error);
      inDensityProgress.add(StreamProgress.DataRetrieved);
    });
  }

  void dispose() {
    _densityController.close();
    _connectionController.close();
  }
}

import 'package:realoptions/blocs/bloc_provider.dart' as bloc_provider;
import 'dart:async';
import 'package:realoptions/services/finside_service.dart';
import 'package:realoptions/models/response.dart';
import 'package:realoptions/models/forms.dart';
import 'package:rxdart/rxdart.dart';
import 'package:realoptions/models/progress.dart';
import 'package:meta/meta.dart';

class OptionsBloc implements bloc_provider.BlocBase {
  final StreamController<Map<String, List<ModelResult>>> _optionController =
      BehaviorSubject();

  final StreamController<StreamProgress> _connectionController =
      BehaviorSubject();
  final FinsideApi finside;
  Stream<Map<String, List<ModelResult>>> get outOptionsController =>
      _optionController.stream;
  StreamSink get _inOptionsController => _optionController.sink;
  Stream<StreamProgress> get outOptionsProgress => _connectionController.stream;
  StreamSink get inOptionsProgress => _connectionController.sink;

  OptionsBloc({@required this.finside}) {
    inOptionsProgress.add(StreamProgress.NoData);
  }

  Future<void> getOptionPrices(Map<String, SubmitItems> submittedBody) {
    SubmitBody body = SubmitBody(formBody: submittedBody);
    inOptionsProgress.add(StreamProgress.Busy);
    return finside.fetchOptionPrices(body.convertSubmission()).then((result) {
      _inOptionsController.add(result);
      inOptionsProgress.add(StreamProgress.DataRetrieved);
    }).catchError((error) {
      _inOptionsController.addError(error);
      inOptionsProgress.add(StreamProgress.DataRetrieved);
    });
  }

  void dispose() {
    _optionController.close();
    _connectionController.close();
  }
}
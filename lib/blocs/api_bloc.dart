import 'package:realoptions/blocs/bloc_provider.dart' as bloc_provider;
import 'dart:async';
import 'package:realoptions/services/persistant_storage_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:realoptions/models/progress.dart';
import 'package:meta/meta.dart';

final String apiKeyId = "apiKey";

class ApiBloc implements bloc_provider.BlocBase {
  final StreamController<String> _keyController = BehaviorSubject();
  final StreamController<StreamProgress> _stateController = BehaviorSubject();
  Future<void> _doneConstructor; //helper function for our tests
  Stream<String> get outApiKey => _keyController.stream;
  Stream<StreamProgress> get outHomeState => _stateController.stream;
  StreamSink get _getApiKey => _keyController.sink;
  StreamSink get _getHomeState => _stateController.sink;
  Future<void> get doneInitialization => _doneConstructor;
  String _apiKey = "";
  final PersistentStorage apiStorage;
  ApiBloc({@required this.apiStorage}) {
    _getHomeState.add(StreamProgress.Busy);
    _doneConstructor = _init();
  }
  Future<void> _init() {
    return apiStorage.retrieveValue(apiKeyId).then((apiKey) {
      if (apiKey != null && apiKey != "") {
        _apiKey = apiKey;
        _getApiKey.add(apiKey);
        _getHomeState.add(StreamProgress.DataRetrieved);
      } else {
        _getHomeState.add(StreamProgress.NoData);
      }
    }).catchError(_stateController.addError);
  }

  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  //used for statically getting apikey, use outApiKey to get streamed results
  String getApiKey() {
    return _apiKey;
  }

  void saveApiKey() {
    _getHomeState.add(StreamProgress.Busy);
    if (_apiKey == "") {
      _getHomeState.add(StreamProgress.NoData);
      apiStorage.removeValue(apiKeyId);
    } else {
      apiStorage.insertValue(apiKeyId, _apiKey).then((_) {
        _getApiKey.add(_apiKey);
        _getHomeState.add(StreamProgress.DataRetrieved);
      }).catchError(_stateController.addError);
    }
  }

  void dispose() {
    _keyController.close();
    _stateController.close();
  }
}

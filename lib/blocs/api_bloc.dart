import 'package:demo_api_app_flutter/blocs/bloc_provider.dart' as bloc_provider;
import 'package:demo_api_app_flutter/models/api_key.dart';
import 'dart:async';
import 'package:demo_api_app_flutter/services/api_key_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:demo_api_app_flutter/models/progress.dart';

final int keyId = 1;

class ApiBloc implements bloc_provider.BlocBase {
  final StreamController<ApiKey> _keyController = BehaviorSubject();
  final StreamController<StreamProgress> _stateController = BehaviorSubject();
  Stream<ApiKey> get outApiKey => _keyController.stream;
  Stream<StreamProgress> get outHomeState => _stateController.stream;
  StreamSink get _getApiKey => _keyController.sink;
  StreamSink get _getHomeState => _stateController.sink;

  String _apiKey = "";
  ApiDB db; // = ApiDB();
  ApiBloc() {
    _getHomeState.add(StreamProgress.Busy);
    db.retrieveKey().then((apiKeyList) {
      if (apiKeyList.length > 0 && apiKeyList.first.key != "") {
        _apiKey = apiKeyList.first.key;
        _getApiKey.add(apiKeyList.first);
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
    ApiKey apiKey = ApiKey(id: keyId, key: _apiKey);
    if (_apiKey == "") {
      _getHomeState.add(StreamProgress.NoData);
      db.removeKey(keyId);
    } else {
      db.insertKey(apiKey).then((result) {
        _getHomeState.add(StreamProgress.DataRetrieved);
        _getApiKey.add(apiKey);
      }).catchError(_stateController.addError);
    }
  }

  void dispose() {
    _keyController.close();
    _stateController.close();
  }
}

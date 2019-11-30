import 'package:demo_api_app_flutter/blocs/bloc_provider.dart' as bloc_provider;
import 'package:demo_api_app_flutter/models/api_key.dart';
import 'dart:async';

import 'package:demo_api_app_flutter/services/api_key.dart' as auth;
import 'package:rxdart/rxdart.dart';
import 'package:demo_api_app_flutter/models/progress.dart';

class ApiBloc implements bloc_provider.BlocBase {
  StreamController<ApiKey> _keyController = BehaviorSubject();
  StreamController<StreamProgress> _stateController = BehaviorSubject();
  Stream<ApiKey> get outApiKey => _keyController.stream;
  Stream<StreamProgress> get outHomeState => _stateController.stream;
  StreamSink get _getApiKey => _keyController.sink;
  StreamSink get _getHomeState => _stateController.sink;

  String _apiKey;
  ApiBloc() {
    _getHomeState.add(StreamProgress.Busy);
    auth.retrieveKey().then((apiKeyList) {
      if (apiKeyList.length > 0 && apiKeyList.first.key != "") {
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

  void saveApiKey() {
    _getHomeState.add(StreamProgress.Busy);
    ApiKey apiKey = ApiKey(id: 1, key: _apiKey);
    auth.insertKey(apiKey).then((result) {
      _getHomeState.add(StreamProgress.DataRetrieved);
      _getApiKey.add(apiKey);
    }).catchError(_stateController.addError);
  }

  void dispose() {
    _keyController.close();
    _stateController.close();
  }
}

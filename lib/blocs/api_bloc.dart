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
  //do I even need this??  I don't think I'll call it
  StreamSink get getApiKey => _keyController.sink;
  StreamSink get getHomeState => _stateController.sink;

  String _apiKey;
  ApiBloc() {
    getHomeState.add(StreamProgress.Busy);
    auth.retrieveKey().then((apiKeyList) {
      if (apiKeyList.length > 0 && apiKeyList.first.key != "") {
        _keyController.sink.add(apiKeyList.first);
        getHomeState.add(StreamProgress.DataRetrieved);
      } else {
        getHomeState.add(StreamProgress.NoData);
      }
    }).catchError(_stateController.addError);
  }
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  void saveApiKey() {
    getHomeState.add(StreamProgress.Busy);
    ApiKey apiKey = ApiKey(id: 1, key: _apiKey);
    auth.insertKey(apiKey).then((result) {
      getHomeState.add(StreamProgress.DataRetrieved);
      _keyController.sink.add(apiKey);
    }).catchError(_stateController.addError);
  }

  void dispose() {
    _keyController.close();
    _stateController.close();
  }
}

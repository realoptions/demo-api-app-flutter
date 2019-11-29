import 'package:demo_api_app_flutter/blocs/bloc_provider.dart' as bloc_provider;
import 'package:demo_api_app_flutter/models/api_key.dart';
import 'dart:async';

import 'package:demo_api_app_flutter/services/api_key.dart' as auth;
import 'package:rxdart/rxdart.dart';

enum HomeViewState { Busy, DataRetrieved, NoData }

class ApiBloc implements bloc_provider.BlocBase {
  StreamController<ApiKey> _keyController = BehaviorSubject();
  StreamController<HomeViewState> _stateController = BehaviorSubject();
  Stream<ApiKey> get outApiKey => _keyController.stream;
  Stream<HomeViewState> get outHomeState => _stateController.stream;
  //do I even need this??  I don't think I'll call it
  StreamSink get getApiKey => _keyController.sink;
  //do I even need this??  I don't think I'll call it
  StreamSink get getHomeState => _stateController.sink;

  String _apiKey;
  ApiBloc() {
    _stateController.sink.add(HomeViewState.Busy);
    auth.retrieveKey().then((apiKeyList) {
      if (apiKeyList.length > 0 && apiKeyList.first.key != "") {
        _keyController.sink.add(apiKeyList.first);
        _stateController.sink.add(HomeViewState.DataRetrieved);
      } else {
        _stateController.sink.add(HomeViewState.NoData);
      }
    });
  }
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  void saveApiKey() {
    _stateController.sink.add(HomeViewState.Busy);
    ApiKey apiKey = ApiKey(id: 1, key: _apiKey);
    auth.insertKey(apiKey).then((result) {
      _stateController.sink.add(HomeViewState.DataRetrieved);
      _keyController.sink.add(apiKey);
    }).catchError((error) {
      //TODO!  Need to add visual logic when error occurs
      _stateController.sink.add(HomeViewState.NoData);
    });
  }

  void dispose() {
    _keyController.close();
    _stateController.close();
  }
}

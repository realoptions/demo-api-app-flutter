import 'package:realoptions/blocs/bloc_provider.dart' as bloc_provider;
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:realoptions/models/progress.dart';
import 'package:meta/meta.dart';
import 'package:firebase_auth/firebase_auth.dart';

final String apiKeyId = "apiKey";

class ApiBloc implements bloc_provider.BlocBase {
  final StreamController<String> _keyController = BehaviorSubject();
  final StreamController<FirebaseAuth> _authController = BehaviorSubject();
  final StreamController<StreamProgress> _stateController = BehaviorSubject();
  Future<void> _doneConstructor; //helper function for our tests
  Stream<String> get outApiKey => _keyController.stream;
  Stream<FirebaseAuth> get outAuth => _authController.stream;
  Stream<StreamProgress> get outHomeState => _stateController.stream;
  StreamSink get _getApiKey => _keyController.sink;
  StreamSink get _getAuth => _authController.sink;
  StreamSink get _getHomeState => _stateController.sink;
  Future<void> get doneInitialization => _doneConstructor;
  final FirebaseAuth firebaseAuth;
  ApiBloc({@required this.firebaseAuth}) {
    _getHomeState.add(StreamProgress.Busy);
    _getAuth.add(firebaseAuth);
    _doneConstructor = _init();
  }
  void setBusy() {
    _getHomeState.add(StreamProgress.Busy);
  }

  Future<void> setKeyFromUser(FirebaseUser user) {
    if (user == null) {
      _getHomeState.add(StreamProgress.NoData);
      return Future.value();
    } else {
      return user.getIdToken().then((idToken) {
        _getApiKey.add(idToken.token);
        _getHomeState.add(StreamProgress.DataRetrieved);
      }).catchError(_stateController.addError);
    }
  }

  Future<void> _init() {
    return firebaseAuth.currentUser().then(setKeyFromUser);
  }

  void dispose() {
    _keyController.close();
    _authController.close();
    _stateController.close();
  }
}

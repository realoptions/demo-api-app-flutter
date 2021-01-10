import 'package:realoptions/blocs/bloc_provider.dart' as bloc_provider;
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:realoptions/models/progress.dart';
import 'package:meta/meta.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bloc/bloc.dart';
import './api_events.dart';
import './api_state.dart';
import '../../repositories/api_repository.dart';

final String apiKeyId = "apiKey";

class ApiBloc extends Bloc<ApiEvents, ApiState> {
  final FirebaseAuth _firebaseAuth;
  //final StreamSubscription<ApiState> _keyController;
  final ApiRepository _apiRepository;
  //final StreamSubscription _stateController;
  ApiBloc(
      {@required FirebaseAuth firebaseAuth,
      @required ApiRepository apiRepository})
      : assert(firebaseAuth != null),
        _firebaseAuth = firebaseAuth,
        _apiRepository = apiRepository,
        super(ApiIsFetching());
  @override
  Stream<ApiState> mapEventToState(ApiEvents event) async* {
    switch (event) {
      case ApiEvents.RequestApiKey:
        yield ApiIsFetching();
        try {
          final user = await _firebaseAuth.currentUser();
          final token = await _apiRepository.getToken(user);
          yield ApiToken({token: token});
        } catch (err) {
          yield ApiError({apiError: err});
        }
        break;
      case ApiEvents.GoogleSignIn:
        final authCredential =
            await _apiRepository.handleGoogleSignIn(_firebaseAuth);
        yield ApiIsFetching();
        await _apiRepository.convertCredentialToUser(
            _firebaseAuth, authCredential);
        add(ApiEvents.RequestApiKey);
        break;
      case ApiEvents.FacebookSignIn:
        final facebookLogin =
            await _apiRepository.handleFacebookSignIn(_firebaseAuth);
        yield ApiIsFetching();
        if (facebookLogin != null) {
          await _apiRepository.convertFacebookToUser(
              _firebaseAuth, facebookLogin);
        }
        add(ApiEvents.RequestApiKey);
        break;
    }
  }

  /*Future<void> setKeyFromUser(FirebaseUser user) {
    if (user == null) {
      //_getHomeState.add(StreamProgress.NoData);
      add(NoApiKey());
      //return Future.value();
    } else {
      return user.getIdToken().then((idToken) {
        add(RetrievedApiKey(idToken.token);
        //_getApiKey.add(idToken.token);
        //_getHomeState.add(StreamProgress.DataRetrieved);
      }).catchError((err)=>add(ApiKeyError(err)));
    }
  }*/
}
/*
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
}*/

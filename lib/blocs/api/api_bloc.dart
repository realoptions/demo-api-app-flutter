import 'dart:async';
import 'package:meta/meta.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bloc/bloc.dart';
import './api_events.dart';
import './api_state.dart';
import '../../repositories/api_repository.dart';

final String apiKeyId = "apiKey";

class ApiBloc extends Bloc<ApiEvents, ApiState> {
  final FirebaseAuth _firebaseAuth;
  final AuthRepository _apiRepository;
  ApiBloc(
      {@required FirebaseAuth firebaseAuth,
      @required AuthRepository apiRepository})
      : assert(firebaseAuth != null),
        _firebaseAuth = firebaseAuth,
        _apiRepository = apiRepository,
        super(ApiIsFetching());

  void handleGoogleSignIn() {
    add(ApiEvents.GoogleSignIn);
  }

  void handleFacebookSignIn() {
    add(ApiEvents.FacebookSignIn);
  }

  @override
  Stream<ApiState> mapEventToState(ApiEvents event) async* {
    switch (event) {
      case ApiEvents.RequestApiKey:
        yield ApiIsFetching();
        try {
          final user = await _firebaseAuth.currentUser();
          final token = await _apiRepository.getToken(user);
          yield ApiToken(token: token);
        } catch (err) {
          yield ApiError(apiError: err);
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
        final authCredential =
            await _apiRepository.handleFacebookSignIn(_firebaseAuth);
        yield ApiIsFetching();
        await _apiRepository.convertCredentialToUser(
            _firebaseAuth, authCredential);

        add(ApiEvents.RequestApiKey);
        break;
    }
  }
}

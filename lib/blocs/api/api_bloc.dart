import 'dart:async';
import 'package:meta/meta.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bloc/bloc.dart';
import './api_events.dart';
import './api_state.dart';
import '../../repositories/api_repository.dart';

final String apiKeyId = "apiKey";

class ApiBloc extends Bloc<ApiEvents, ApiState> {
  final FirebaseAuth firebaseAuth;
  final AuthRepository apiRepository;
  ApiBloc({@required this.firebaseAuth, @required this.apiRepository})
      : assert(firebaseAuth != null),
        super(ApiIsFetching());

  void handleGoogleSignIn() {
    add(ApiEvents.GoogleSignIn);
  }

  void handleFacebookSignIn() {
    add(ApiEvents.FacebookSignIn);
  }

  void setNoData() {
    add(ApiEvents.SignOut);
  }

  @override
  Stream<ApiState> mapEventToState(ApiEvents event) async* {
    switch (event) {
      case ApiEvents.SignOut:
        yield ApiNoData();
        break;
      case ApiEvents.RequestApiKey:
        yield ApiIsFetching();
        try {
          final user = firebaseAuth.currentUser;
          if (user != null) {
            final token = await apiRepository.getToken(user);
            yield ApiToken(token: token);
          } else {
            yield ApiNoData();
          }
        } catch (err) {
          yield ApiError(apiError: err);
        }
        break;
      case ApiEvents.GoogleSignIn:
        final authCredential =
            await apiRepository.handleGoogleSignIn(firebaseAuth);
        yield ApiIsFetching();
        await apiRepository.convertCredentialToUser(
            firebaseAuth, authCredential);
        add(ApiEvents.RequestApiKey);
        break;
      case ApiEvents.FacebookSignIn:
        final authCredential =
            await apiRepository.handleFacebookSignIn(firebaseAuth);
        yield ApiIsFetching();
        await apiRepository.convertCredentialToUser(
            firebaseAuth, authCredential);

        add(ApiEvents.RequestApiKey);
        break;
    }
  }
}

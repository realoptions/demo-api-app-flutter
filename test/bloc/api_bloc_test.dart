import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/api/api_bloc.dart';
import 'package:realoptions/blocs/api/api_state.dart';
import 'package:realoptions/blocs/api/api_events.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import '../../mocks/api_repository_mock.dart';
import 'package:bloc_test/bloc_test.dart';

void main() {
  MockFirebaseAuth auth;
  MockApiRepository apiRepository;
  ApiBloc bloc;
  setUp(() {
    auth = MockFirebaseAuth(signedIn: true);
    apiRepository = MockApiRepository();
    bloc = ApiBloc(firebaseAuth: auth, apiRepository: apiRepository);
  });
  tearDown(() {
    auth = null;
    bloc.close();
  });
  test('correct initial state', () async {
    expect(bloc.state, ApiIsFetching());
  });
  blocTest(
    'emits [fetching, token] when RequestApiKey is added',
    build: () => bloc,
    act: (bloc) => bloc.add(ApiEvents.RequestApiKey),
    expect: [ApiIsFetching(), ApiToken(token: "fake_token")],
  );
}

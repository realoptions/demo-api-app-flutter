import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/api/api_bloc.dart';
import 'package:realoptions/blocs/api/api_state.dart';
import 'package:realoptions/blocs/api/api_events.dart';
import 'package:realoptions/models/progress.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import '../mocks/api_repository_mock.dart';
import 'package:bloc_test/bloc_test.dart';

void main() {
  MockFirebaseAuth auth;
  MockFirebaseUser user;
  MockApiRepository apiRepository;
  ApiBloc bloc;
  setUp(() {
    auth = MockFirebaseAuth(signedIn: true);
    user = MockFirebaseUser();
    bloc = ApiBloc(firebaseAuth: auth, apiRepository: apiRepository);
  });
  tearDown(() {
    auth = null;
    user = null;
    bloc = null;
  });
  test('executes api creation in correct order', () async {
    expect(bloc.state, ApiIsFetching());
    //await bloc.doneInitialization;
    //bloc.setKeyFromUser(user);
    //expect(bloc.outApiKey, emitsInOrder(["fake_token", "fake_token"]));
  });
  blocTest(
    'emits [1] when CounterEvent.increment is added',
    build: () => bloc,
    act: (bloc) => bloc.add(ApiEvents.RequestApiKey),
    expect: [ApiIsFetching(), ApiToken(token: "hello")],
  );
  /*test('when key is retrieved, stream shows that data is retrieved', () {
    ApiBloc bloc = ApiBloc(firebaseAuth: auth);
    expect(bloc.outHomeState,
        emitsInOrder([StreamProgress.Busy, StreamProgress.DataRetrieved]));
  });
  test('when set busy emits busy', () async {
    ApiBloc bloc = ApiBloc(firebaseAuth: auth);
    await bloc.doneInitialization;
    bloc.setBusy();
    expect(bloc.outHomeState, emitsInOrder([StreamProgress.Busy]));
  });*/
}

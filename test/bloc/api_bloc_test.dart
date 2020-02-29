import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/api_bloc.dart';
import 'package:realoptions/models/progress.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  MockFirebaseAuth auth;
  MockFirebaseUser user;

  setUp(() {
    auth = MockFirebaseAuth();
    user = MockFirebaseUser();
  });
  tearDown(() {
    auth = null;
    user = null;
  });
  test('executes api creation in correct order', () async {
    //stubRetrieveData();
    ApiBloc bloc = ApiBloc(firebaseAuth: auth);
    await bloc.doneInitialization;
    bloc.setKeyFromUser(user);
    //expect(bloc.getApiKey(), "Hello");
    expect(bloc.outApiKey, emitsInOrder(["fake_token", "fake_token"]));
  });
  test('when key is retrieved, stream shows that data is retrieved', () {
    ApiBloc bloc = ApiBloc(firebaseAuth: auth);
    expect(bloc.outHomeState,
        emitsInOrder([StreamProgress.Busy, StreamProgress.DataRetrieved]));
  });
  test('if no key, stream shows no data', () {
    ApiBloc bloc = ApiBloc(firebaseAuth: auth);
    bloc.setKeyFromUser(null);
    expect(bloc.outHomeState,
        emitsInOrder([StreamProgress.Busy, StreamProgress.NoData]));
  });
}

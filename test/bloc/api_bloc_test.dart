import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/api_bloc.dart';
import 'package:realoptions/models/progress.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  MockFirebaseAuth auth;
  MockFirebaseUser user;

  setUp(() {
    auth = MockFirebaseAuth(signedIn: true);
    user = MockFirebaseUser();
  });
  tearDown(() {
    auth = null;
    user = null;
  });
  test('executes api creation in correct order', () async {
    ApiBloc bloc = ApiBloc(firebaseAuth: auth);
    await bloc.doneInitialization;
    bloc.setKeyFromUser(user);
    expect(bloc.outApiKey, emitsInOrder(["fake_token", "fake_token"]));
  });
  test('when key is retrieved, stream shows that data is retrieved', () {
    ApiBloc bloc = ApiBloc(firebaseAuth: auth);
    expect(bloc.outHomeState,
        emitsInOrder([StreamProgress.Busy, StreamProgress.DataRetrieved]));
  });
}

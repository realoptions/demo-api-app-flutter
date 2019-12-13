import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
//import "dart:async";
import 'package:realoptions/blocs/api_bloc.dart';
import 'package:realoptions/services/persistant_storage_service.dart';
import 'package:realoptions/models/progress.dart';

class MockPersistentStorage extends Mock implements PersistentStorage {}

void main() {
  MockPersistentStorage apiStorage;

  setUp(() {
    apiStorage = MockPersistentStorage();
  });
  tearDown(() {
    apiStorage = null;
  });
  void stubRetrieveData() {
    String key = "somekey";
    when(apiStorage.retrieveValue(any)).thenAnswer((_) => Future.value(key));
  }

  void stubRetrieveNoData() {
    when(apiStorage.retrieveValue(any)).thenAnswer((_) => Future.value());
  }

  void stubInsertKey() {
    when(apiStorage.insertValue(any, any)).thenAnswer((_) => Future.value());
  }

  void stubRemoveKey() {
    when(apiStorage.removeValue(any)).thenAnswer((_) => Future.value());
  }

  test('starts with empty apiKey', () async {
    stubRetrieveNoData();
    ApiBloc bloc = ApiBloc(apiStorage: apiStorage);
    await bloc.doneInitialization;
    expect(bloc.getApiKey(), "");
  });
  test('executes api creation in correct order', () async {
    stubInsertKey();
    stubRetrieveData();
    ApiBloc bloc = ApiBloc(apiStorage: apiStorage);
    await bloc.doneInitialization;
    bloc.setApiKey("Hello");
    expect(bloc.getApiKey(), "Hello");
    bloc.saveApiKey();
    expect(bloc.outApiKey, emitsInOrder(["somekey", "Hello"]));
  });
  test('when api is set, can be retrevied through "get"', () async {
    stubInsertKey();
    stubRetrieveData();
    ApiBloc bloc = ApiBloc(apiStorage: apiStorage);
    await bloc.doneInitialization;
    bloc.setApiKey("Hello");
    expect(bloc.getApiKey(), "Hello");
    expect(
        //note that getApiKey is a getter for _apiKey, but is not emitted until "saveApiKey" is called
        bloc.outApiKey,
        emitsInOrder(["somekey"]));
  });
  test('when key is retrieved, _apiKey is set', () async {
    stubInsertKey();
    stubRetrieveData();
    ApiBloc bloc = ApiBloc(apiStorage: apiStorage);
    await bloc.doneInitialization;
    expect(bloc.getApiKey(), "somekey");
  });
  test('when key is retrieved, stream shows that data is retrieved', () {
    stubInsertKey();
    stubRetrieveData();
    ApiBloc bloc = ApiBloc(apiStorage: apiStorage);
    expect(bloc.outHomeState,
        emitsInOrder([StreamProgress.Busy, StreamProgress.DataRetrieved]));
  });
  test('when key is retrieved, stream shows that data is retrieved', () {
    stubInsertKey();
    stubRetrieveData();
    ApiBloc bloc = ApiBloc(apiStorage: apiStorage);
    expect(bloc.outHomeState,
        emitsInOrder([StreamProgress.Busy, StreamProgress.DataRetrieved]));
  });
  test('if no key, _apiKey is empty string', () async {
    stubInsertKey();
    stubRetrieveNoData();
    ApiBloc bloc = ApiBloc(apiStorage: apiStorage);
    await bloc.doneInitialization;
    expect(bloc.getApiKey(), "");
  });
  test('if no key, stream shows no data', () {
    stubInsertKey();
    stubRetrieveNoData();
    ApiBloc bloc = ApiBloc(apiStorage: apiStorage);
    expect(bloc.outHomeState,
        emitsInOrder([StreamProgress.Busy, StreamProgress.NoData]));
  });
  test('if no key, progress streams NoData', () async {
    stubRemoveKey();
    stubRetrieveNoData();
    ApiBloc bloc = ApiBloc(apiStorage: apiStorage);

    expect(
        bloc.outHomeState,
        emitsInOrder([
          StreamProgress.Busy,
          StreamProgress.NoData,
          StreamProgress.Busy,
          StreamProgress.NoData
        ]));
    await bloc.doneInitialization;
    bloc.saveApiKey();
  });
  test('if starts with key, but key is set to nothing, submit does not emit',
      () async {
    stubRemoveKey();
    stubRetrieveData();
    ApiBloc bloc = ApiBloc(apiStorage: apiStorage);
    expect(bloc.outApiKey, emitsInOrder(["somekey"]));
    expect(
        bloc.outHomeState,
        emitsInOrder([
          StreamProgress.Busy,
          StreamProgress.DataRetrieved,
          StreamProgress.Busy,
          StreamProgress.NoData
        ]));
    await bloc.doneInitialization;
    bloc.setApiKey("");
    bloc.saveApiKey();
  });
}

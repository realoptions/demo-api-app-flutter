import 'package:demo_api_app_flutter/models/api_key.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
//import "dart:async";
import 'package:demo_api_app_flutter/blocs/api_bloc.dart';
import 'package:demo_api_app_flutter/services/api_key_service.dart';
import 'package:demo_api_app_flutter/models/progress.dart';

class MockApiDB extends Mock implements ApiDB {}

void main() {
  MockApiDB db;

  setUp(() {
    db = MockApiDB();
  });
  tearDown(() {
    db = null;
  });
  void stubRetrieveData() {
    ApiKey key = ApiKey(id: 1, key: "somekey");
    when(db.retrieveKey()).thenAnswer((_) => Future.value([key]));
  }

  void stubRetrieveNoData() {
    when(db.retrieveKey()).thenAnswer((_) => Future.value([]));
  }

  void stubInsertKey() {
    when(db.insertKey(any)).thenAnswer((_) => Future.value());
  }

  void stubRemoveKey() {
    when(db.removeKey(any)).thenAnswer((_) => Future.value());
  }

  test('starts with empty apiKey', () async {
    stubRetrieveNoData();
    ApiBloc bloc = ApiBloc(db: db);
    await bloc.doneInitialization;
    expect(bloc.getApiKey(), "");
  });
  test('executes api creation in correct order', () async {
    stubInsertKey();
    stubRetrieveData();
    ApiBloc bloc = ApiBloc(db: db);
    await bloc.doneInitialization;
    bloc.setApiKey("Hello");
    expect(bloc.getApiKey(), "Hello");
    bloc.saveApiKey();
    expect(
        bloc.outApiKey,
        emitsInOrder(
            [ApiKey(id: 1, key: "somekey"), ApiKey(id: 1, key: "Hello")]));
  });
  test('when api is set, can be retrevied through "get"', () async {
    stubInsertKey();
    stubRetrieveData();
    ApiBloc bloc = ApiBloc(db: db);
    await bloc.doneInitialization;
    bloc.setApiKey("Hello");
    expect(bloc.getApiKey(), "Hello");
    expect(
        //note that getApiKey is a getter for _apiKey, but is not emitted until "saveApiKey" is called
        bloc.outApiKey,
        emitsInOrder([ApiKey(id: 1, key: "somekey")]));
  });
  test('when key is retrieved, _apiKey is set', () async {
    stubInsertKey();
    stubRetrieveData();
    ApiBloc bloc = ApiBloc(db: db);
    await bloc.doneInitialization;
    expect(bloc.getApiKey(), "somekey");
  });
  test('when key is retrieved, stream shows that data is retrieved', () {
    stubInsertKey();
    stubRetrieveData();
    ApiBloc bloc = ApiBloc(db: db);
    expect(bloc.outHomeState,
        emitsInOrder([StreamProgress.Busy, StreamProgress.DataRetrieved]));
  });
  test('when key is retrieved, stream shows that data is retrieved', () {
    stubInsertKey();
    stubRetrieveData();
    ApiBloc bloc = ApiBloc(db: db);
    expect(bloc.outHomeState,
        emitsInOrder([StreamProgress.Busy, StreamProgress.DataRetrieved]));
  });
  test('if no key, _apiKey is empty string', () async {
    stubInsertKey();
    stubRetrieveNoData();
    ApiBloc bloc = ApiBloc(db: db);
    await bloc.doneInitialization;
    expect(bloc.getApiKey(), "");
  });
  test('if no key, stream shows no data', () {
    stubInsertKey();
    stubRetrieveNoData();
    ApiBloc bloc = ApiBloc(db: db);
    expect(bloc.outHomeState,
        emitsInOrder([StreamProgress.Busy, StreamProgress.NoData]));
  });
  test('if no key, progress streams NoData', () async {
    stubRemoveKey();
    stubRetrieveNoData();
    ApiBloc bloc = ApiBloc(db: db);

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
    ApiBloc bloc = ApiBloc(db: db);
    expect(bloc.outApiKey, emitsInOrder([ApiKey(id: 1, key: "somekey")]));
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

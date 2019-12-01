import 'package:flutter_test/flutter_test.dart';
import 'package:demo_api_app_flutter/blocs/constraints_bloc.dart';
import 'package:demo_api_app_flutter/models/progress.dart';

void main() {
  test('gets correct progress updates on mock server', () {
    ConstraintsBloc bloc = ConstraintsBloc("heston", "somekey");
    expect(bloc.outConstraintsProgress,
        emitsInOrder([StreamProgress.Busy, StreamProgress.DataRetrieved]));
  });
}

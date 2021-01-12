import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/select_model/select_model_bloc.dart';
import 'package:realoptions/models/models.dart';

void main() {
  test('correct initial state', () {
    SelectModelBloc bloc = SelectModelBloc();
    expect(bloc.state, Model(label: "Heston", value: "heston"));
  });
  blocTest('emits other model when setting model',
      build: () => SelectModelBloc(),
      act: (bloc) => bloc.setModel(Model(label: "CGMY", value: "cgmy")),
      expect: [Model(label: "CGMY", value: "cgmy")]);
}

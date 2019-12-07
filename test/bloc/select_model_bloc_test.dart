import 'package:flutter_test/flutter_test.dart';
import 'package:demo_api_app_flutter/blocs/select_model_bloc.dart';
import 'package:demo_api_app_flutter/models/models.dart';

void main() {
  test('emits first model choice on instantiation', () {
    SelectModelBloc bloc = SelectModelBloc();
    expect(bloc.outSelectedModel,
        emitsInOrder([Model(label: "Heston", value: "heston")]));
  });
  test('emits other model when setting model', () {
    SelectModelBloc bloc = SelectModelBloc();
    expect(
        bloc.outSelectedModel,
        emitsInOrder([
          Model(label: "Heston", value: "heston"),
          Model(label: "CGMY", value: "cgmy")
        ]));
    bloc.setModel("cgmy");
  });
  test('emits nothing if model input does not exist', () {
    SelectModelBloc bloc = SelectModelBloc();
    expect(
        bloc.outSelectedModel,
        emitsInOrder([
          Model(label: "Heston", value: "heston"),
          Model(label: "Heston", value: "heston")
        ]));
    bloc.setModel("non existant");
  });
}

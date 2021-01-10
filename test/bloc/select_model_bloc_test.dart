import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/select_model/select_model_bloc.dart';
import 'package:realoptions/models/models.dart';

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
    bloc.setModel(Model(value: "cgmy", label: "CGMY"));
  });
}

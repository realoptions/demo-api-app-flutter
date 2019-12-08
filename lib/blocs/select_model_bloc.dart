import 'package:realoptions/blocs/bloc_provider.dart';
import 'dart:async';
import 'package:realoptions/models/models.dart';
import 'package:rxdart/rxdart.dart';

const List<Model> modelChoices = const <Model>[
  const Model(label: "Heston", value: "heston"),
  const Model(label: "CGMY", value: "cgmy"),
  const Model(label: "Merton", value: "merton")
];

class SelectModelBloc implements BlocBase {
  final StreamController<Model> _modelController = BehaviorSubject();
  Stream<Model> get outSelectedModel => _modelController.stream;
  StreamSink get _getSelectedModel => _modelController.sink;

  SelectModelBloc() {
    _getSelectedModel.add(modelChoices[0]);
  }
  void setModel(String modelValue) {
    _getSelectedModel.add(modelChoices.firstWhere(
        (model) => model.value == modelValue,
        orElse: () => modelChoices[0]));
  }

  void dispose() {
    _modelController.close();
  }
}

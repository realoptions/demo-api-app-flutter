import 'package:demo_api_app_flutter/blocs/bloc_provider.dart';
import 'dart:async';
import 'package:demo_api_app_flutter/models/models.dart';
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
    _getSelectedModel
        .add(modelChoices.firstWhere((model) => model.value == modelValue));
  }

  void dispose() {
    _modelController.close();
  }
}

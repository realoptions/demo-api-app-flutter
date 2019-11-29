import 'package:demo_api_app_flutter/blocs/bloc_provider.dart';
import 'dart:async';
import 'package:demo_api_app_flutter/models/models.dart';

const List<Model> modelChoices = const <Model>[
  const Model(label: "Heston", value: "heston"),
  const Model(label: "CGMY", value: "cgmy"),
  const Model(label: "Merton", value: "merton")
];

class SelectModelBloc implements BlocBase {
  StreamController<Model> _modelController = StreamController<Model>();
  Stream<Model> get outSelectedModel => _modelController.stream;
  StreamSink get _getSelectedModel => _modelController.sink;

  StreamController _actionController = StreamController();
  StreamSink get setModel => _actionController.sink;

  SelectModelBloc() {
    _actionController.stream.listen(_setModel);
    _getSelectedModel.add(modelChoices[0]);
  }
  void _setModel(Model model) {
    _getSelectedModel.add(model);
  }

  void dispose() {
    _modelController.close();
    _actionController.close();
  }
}

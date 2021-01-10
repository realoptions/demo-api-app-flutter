import 'package:realoptions/blocs/bloc_provider.dart';
import 'dart:async';
import 'package:realoptions/models/models.dart';
import 'package:rxdart/rxdart.dart';

class SelectModelBloc implements BlocBase {
  final StreamController<Model> _modelController = BehaviorSubject();
  Stream<Model> get outSelectedModel => _modelController.stream;
  StreamSink get _getSelectedModel => _modelController.sink;

  SelectModelBloc() {
    _getSelectedModel.add(MODEL_CHOICES[0]);
  }
  void setModel(Model modelValue) {
    _getSelectedModel.add(modelValue);
  }

  void dispose() {
    _modelController.close();
  }
}

import 'package:demo_api_app_flutter/blocs/bloc_provider.dart';
import 'dart:async';
import 'package:demo_api_app_flutter/models/forms.dart';
import 'package:demo_api_app_flutter/models/progress.dart';
import 'package:demo_api_app_flutter/services/finside_service.dart';
import 'package:rxdart/rxdart.dart';

class ConstraintsBloc implements BlocBase {
  final StreamController<List<InputConstraint>> _constraintsController =
      BehaviorSubject();
  final StreamController<StreamProgress> _connectionController =
      BehaviorSubject();
  Stream<List<InputConstraint>> get outConstraintsController =>
      _constraintsController.stream;
  StreamSink get _inConstraintsController => _constraintsController.sink;

  Stream<StreamProgress> get outConstraintsProgress =>
      _connectionController.stream;
  StreamSink get _inConstraintsProgress => _connectionController.sink;

  ConstraintsBloc(String model, String apiKey) {
    _inConstraintsProgress.add(StreamProgress.Busy);
    fetchConstraints(model, apiKey).then((result) {
      _inConstraintsProgress.add(StreamProgress.DataRetrieved);
      _inConstraintsController.add(result);
    }).catchError((error) {
      _inConstraintsController.addError(error);
    });
  }

  void dispose() {
    _constraintsController.close();
    _connectionController.close();
  }
}

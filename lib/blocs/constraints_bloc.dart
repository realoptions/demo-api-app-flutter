import 'package:demo_api_app_flutter/blocs/bloc_provider.dart';
import 'dart:async';
import 'package:demo_api_app_flutter/models/forms.dart';
import 'package:demo_api_app_flutter/models/progress.dart';
import 'package:demo_api_app_flutter/services/finside_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:meta/meta.dart';

class ConstraintsBloc implements BlocBase {
  final StreamController<List<InputConstraint>> _constraintsController =
      BehaviorSubject();
  final StreamController<StreamProgress> _connectionController =
      BehaviorSubject();
  final FinsideApi finside;
  Future<void> _doneConstructor;

  Future<void> get doneInitialization => _doneConstructor;
  Stream<List<InputConstraint>> get outConstraintsController =>
      _constraintsController.stream;
  StreamSink get _inConstraintsController => _constraintsController.sink;

  Stream<StreamProgress> get outConstraintsProgress =>
      _connectionController.stream;
  StreamSink get _inConstraintsProgress => _connectionController.sink;

  ConstraintsBloc({@required this.finside}) {
    _inConstraintsProgress.add(StreamProgress.Busy);
    _doneConstructor = _init();
  }

  Future<void> _init() {
    return finside.fetchConstraints().then((result) {
      _inConstraintsController.add(result);
      _inConstraintsProgress.add(StreamProgress.DataRetrieved);
    }).catchError((error) {
      _inConstraintsController.addError(error);
    });
  }

  void dispose() {
    _constraintsController.close();
    _connectionController.close();
  }
}

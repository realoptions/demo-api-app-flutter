import 'package:demo_api_app_flutter/blocs/bloc_provider.dart';
import 'dart:async';
import 'package:demo_api_app_flutter/models/forms.dart';
import 'package:demo_api_app_flutter/services/api_consume.dart';
import 'package:rxdart/rxdart.dart';
//import 'package:flutter/material.dart';

class ConstraintsBloc implements BlocBase {
  StreamController<InputConstraints> _constraintsController = BehaviorSubject();
  Stream<InputConstraints> get outConstraintsController =>
      _constraintsController.stream;
  StreamSink get _inConstraintsController => _constraintsController.sink;

  ConstraintsBloc(String model, String apiKey) {
    //_inConstraintsController.add(ConnectionState.waiting);
    fetchConstraints(model, apiKey).then((result) {
      _inConstraintsController.add(result);
      //_inConstraintsController.add(ConnectionState.done);
    });
  }

  void dispose() {
    _constraintsController.close();
  }
}

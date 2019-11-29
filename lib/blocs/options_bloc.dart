import 'package:demo_api_app_flutter/blocs/bloc_provider.dart' as bloc_provider;
import 'dart:async';
import 'package:demo_api_app_flutter/services/api_consume.dart';
import 'package:demo_api_app_flutter/models/response.dart';
import 'package:demo_api_app_flutter/models/forms.dart';
import 'package:demo_api_app_flutter/utils/services.dart';

class OptionsBloc implements bloc_provider.BlocBase {
  StreamController<List<ModelResult>> _callController =
      StreamController<List<ModelResult>>();
  StreamController<List<ModelResult>> _putController =
      StreamController<List<ModelResult>>();

  Stream<List<ModelResult>> get outCallResults => _callController.stream;
  Stream<List<ModelResult>> get outPutResults => _putController.stream;

  OptionsBloc();

  void getOptionPrices(
      String model, String apiKey, Map<String, SubmitItems> submittedBody) {
    var body = convertSubmission(submittedBody, generateStrikes);

    fetchOptionPrices(model, apiKey, body).then((results) {
      _callController.sink.add(results["call"].results);
      _putController.sink.add(results["put"].results);
    });
  }

  void dispose() {
    _callController.close();
    _putController.close();
  }
}

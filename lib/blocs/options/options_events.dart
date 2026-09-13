import 'package:realoptions/models/api_request.dart';

abstract class OptionsEvents {
  const OptionsEvents();
}

class RequestOptions extends OptionsEvents {
  const RequestOptions({required this.request});

  final CalculationRequest request;
}

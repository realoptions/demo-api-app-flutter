import 'package:realoptions/models/api_request.dart';

abstract class DensityEvents {
  const DensityEvents();
}

class RequestDensity extends DensityEvents {
  const RequestDensity({required this.request});

  final CalculationRequest request;
}

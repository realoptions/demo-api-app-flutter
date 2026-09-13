import 'package:realoptions/models/models.dart';

abstract class ConstraintsEvents {
  const ConstraintsEvents();
}

class RequestConstraints extends ConstraintsEvents {
  final Model model;
  const RequestConstraints({required this.model});
}

import 'package:bloc/bloc.dart';
import 'package:realoptions/models/models.dart';

class SelectModelBloc extends Cubit<Model> {
  SelectModelBloc() : super(MODEL_CHOICES[0]);
  void setModel(Model modelValue) {
    emit(modelValue);
  }
}

import 'dart:math';

import 'package:equatable/equatable.dart';

abstract class PropertiesFormState extends Equatable {
  const PropertiesFormState();
}

class InitialFormState extends PropertiesFormState {
  @override
  List<Object> get props => [];
}

/// It seems to not be used but it actually updates the form when yielded
class DeletedLastRow extends PropertiesFormState {
  final int id = Random().nextInt(100000);

  DeletedLastRow();

  @override
  List<Object> get props => [id];
}
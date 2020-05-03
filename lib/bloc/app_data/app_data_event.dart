import 'dart:math';
import 'package:equatable/equatable.dart';

abstract class AppDataEvent extends Equatable {
  const AppDataEvent();
}

class InitializeEvent extends AppDataEvent {
  @override
  List<Object> get props => [];
}

class UpdateUIEvent extends AppDataEvent {
  final int id = Random().nextInt(10000);

  @override
  List<Object> get props => [id];
}

class LoadingEvent extends AppDataEvent {
  @override
  List<Object> get props => [];
}
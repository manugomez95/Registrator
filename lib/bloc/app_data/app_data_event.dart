import 'package:bitacora/bloc/database/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

abstract class AppDataEvent extends Equatable {
  const AppDataEvent();
}

class AltUpdateUIEvent extends AppDataEvent {
  final UniqueKey key;

  AltUpdateUIEvent(this.key);

  @override
  List<Object> get props => [key];
}

class UpdateUIEvent extends AppDataEvent {
  final DatabaseEvent event;

  UpdateUIEvent(this.event);

  @override
  List<Object> get props => [event];
}

class LoadingEvent extends AppDataEvent {
  @override
  List<Object> get props => [];
}
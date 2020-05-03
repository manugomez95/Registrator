import 'package:equatable/equatable.dart';
import 'package:stack/stack.dart';
import 'app_data_event.dart';

abstract class AppDataState extends Equatable {
  final Stack<AppDataEvent> loadingStack;

  const AppDataState(this.loadingStack);
}

class InitialAppDataState extends AppDataState {
  InitialAppDataState(Stack<AppDataEvent> loadingStack) : super(loadingStack);

  @override
  List<Object> get props => [];
}

class InitCompleted extends AppDataState {
  InitCompleted(Stack<AppDataEvent> loadingStack) : super(loadingStack);

  @override
  List<Object> get props => [];
}

class UpdateUI extends AppDataState {
  final UpdateUIEvent id;

  UpdateUI(this.id, Stack<AppDataEvent> loadingStack) : super(loadingStack);

  @override
  List<Object> get props => [id, loadingStack];
}

class Loading extends AppDataState {
  Loading(Stack<AppDataEvent> loadingStack) : super(loadingStack);

  @override
  List<Object> get props => [loadingStack];
}

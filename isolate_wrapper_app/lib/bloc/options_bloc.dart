import 'dart:isolate';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isolate_wrapper/isolate_wrapper.dart';
import 'package:isolate_wrapper_app/bloc/isolate_bloc_events.dart';
import 'package:isolate_wrapper_app/bloc/isolate_bloc_state.dart';

class OptionsBlocEvent {}

class OptionsBlocEventChangeRunOnce extends OptionsBlocEvent {
  final bool runOnce;
  OptionsBlocEventChangeRunOnce(this.runOnce);
}

class OptionsBlocEventChangeSpeed extends OptionsBlocEvent {
  final int speed;
  OptionsBlocEventChangeSpeed(this.speed);
}

class OptionsBlocEventAwaitResult extends OptionsBlocEvent {
  final bool awaitResult;
  OptionsBlocEventAwaitResult(this.awaitResult);
}

class OptionsBlocState {
  final bool runOnce;
  final bool awaitResult;
  final int speed;
  OptionsBlocState(this.runOnce, this.awaitResult, this.speed);
}

class OptionsBloc extends Bloc<OptionsBlocEvent, OptionsBlocState> {
  MultiIsolateManager mgr;

  OptionsBloc(this.mgr) : super(OptionsBlocState(true, true, 2)) {
    // on<OptionsBlocEventChangeRunOnce>(_onIsolateBlocEventStart);
    // on<OptionsBlocEventChangeSpeed>(_onIsolateBlocEventStop);
    // on<OptionsBlocEventAwaitResult>(_onIsolateBlocEventUpdateList);
  }
  Future<void> _onIsolateBlocEventUpdateList(
      IsolateBlocEventUpdateList event, Emitter<IsolateBlocState> emit) async {
    emit(IsolateBlocState(event.list));
  }
}

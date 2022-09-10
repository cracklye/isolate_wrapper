import 'dart:isolate';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isolate_wrapper/isolate_wrapper.dart';
import 'package:isolate_wrapper_app/bloc/isolate_bloc_events.dart';
import 'package:isolate_wrapper_app/bloc/isolate_bloc_state.dart';

class IsolateBloc extends Bloc<IsolateBlocEvent, IsolateBlocState> {
  MultiIsolateManager mgr;

  IsolateBloc(this.mgr) : super(IsolateBlocState({})) {
    on<IsolateBlocEventStart>(_onIsolateBlocEventStart);
    on<IsolateBlocEventStop>(_onIsolateBlocEventStop);

    mgr.getUpdateStream().listen((event) {
      add(IsolateBlocEventUpdateList(event));
    });
  }

  Future<void> _onIsolateBlocEventStart(
      IsolateBlocEventStart event, Emitter<IsolateBlocState> emit) async {
    IsolateWrapper? isolate;
    if (event.startNo == 0) {
      isolate = IsolateWrapper(handleSendResultInit);
    } else if (event.startNo == 1) {
      isolate = IsolateWrapper(handleSendResultInit);
    } else if (event.startNo == 2) {
      isolate = IsolateWrapper(handleSendResultInit);
    }
    if (isolate != null) {
      mgr.run(isolate);
    }
  }

  Future<void> _onIsolateBlocEventStop(
      IsolateBlocEventStop event, Emitter<IsolateBlocState> emit) async {
    mgr.stop(event.isolateId);
  }
}

void handleSendResultInit(SendPort sendPort) async {
  var reciever = IsolateWrapperReciever(sendPort,
      onInit: (dynamic message, reciever) async {
    reciever.sendProgress("Have initialised", 2);
  }, onMessage: (msg, rcv) async {
    rcv.sendProgress("Have Recieved message, about to start long process", 10);

    for (int i = 2; i < 10; i++) {
      await Future.delayed(const Duration(seconds: 2));
      rcv.sendProgress("Updated process to stage $i", i * 10);
    }

    rcv.sendProgress("Cleaning up process", 90);
  });
  await reciever.start();
}

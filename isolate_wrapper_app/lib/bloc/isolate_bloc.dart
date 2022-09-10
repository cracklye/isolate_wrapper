import 'dart:isolate';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isolate_wrapper/isolate_wrapper.dart';
import 'package:isolate_wrapper_app/bloc/isolate_bloc_events.dart';
import 'package:isolate_wrapper_app/bloc/isolate_bloc_state.dart';

class IsolateBloc extends Bloc<IsolateBlocEvent, IsolateBlocState> {
  MultiIsolateManager mgr;

  IsolateBloc(this.mgr) : super(IsolateBlocState([])) {
    on<IsolateBlocEventStart>(_onIsolateBlocEventStart);
    on<IsolateBlocEventStop>(_onIsolateBlocEventStop);
    on<IsolateBlocEventUpdateList>(_onIsolateBlocEventUpdateList);

    mgr.getUpdateStream().listen((event) {
      add(IsolateBlocEventUpdateList(event));
    });
  }
  Future<void> _onIsolateBlocEventUpdateList(
      IsolateBlocEventUpdateList event, Emitter<IsolateBlocState> emit) async {
    emit(IsolateBlocState(event.list));
  }

  Future<void> _onIsolateBlocEventStart(
      IsolateBlocEventStart event, Emitter<IsolateBlocState> emit) async {
    Function(SendPort sendPort)? isolate;
    String description = ""; 

    if (event.startNo == 0) {
      //Fast
      isolate = handleSendResultFast;
      description = "Running Fast"; 
    } else if (event.startNo == 1) {
      //Slow
      isolate = handleSendResultSlow;
      description = "Running Slow"; 
    } else if (event.startNo == 2) {
      isolate = handleSendResultSuperSlow;
      description = "Running Super Slow"; 
    }
    if (isolate != null) {
      mgr.run(isolate, description: description);
    }
  }

  Future<void> _onIsolateBlocEventStop(
      IsolateBlocEventStop event, Emitter<IsolateBlocState> emit) async {
    mgr.stop(event.isolateId);
  }
}

void handleSendResultFast(SendPort sendPort) async {
  var reciever = IsolateWrapperReciever(
    sendPort,
    onInit: (dynamic message, reciever) async {
      reciever.sendProgress("Have initialised", 2);

      for (int i = 2; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 80));
        reciever.sendProgress("Updated process to stage $i", i * 10);
      }

      reciever.sendProgress("Cleaning up process", 90);
      reciever.sendResult("Completed The Result");
      
    },
  );
  await reciever.start();
}

void handleSendResultSlow(SendPort sendPort) async {
  var reciever = IsolateWrapperReciever(
    sendPort,
    onInit: (dynamic message, reciever) async {
      reciever.sendProgress("Have initialised", 2);
      for (int i = 2; i < 10; i++) {
        await Future.delayed(const Duration(seconds: 2));
        reciever.sendProgress("Updated process to stage $i", i * 10);
      }

      reciever.sendProgress("Cleaning up process", 90);
      reciever.sendResult("All Done");
    },
  );

  await reciever.start();
}

void handleSendResultSuperSlow(SendPort sendPort) async {
  var reciever = IsolateWrapperReciever(
    sendPort,
    onInit: (dynamic message, reciever) async {
      reciever.sendProgress("Have initialised", 2);
      for (int i = 2; i < 10; i++) {
        await Future.delayed(const Duration(seconds: 10));
        reciever.sendProgress("Updated process to stage $i", i * 10);
      }

      reciever.sendProgress("Cleaning up process", 90);
      reciever.sendResult("All Done");
    },
  );

  await reciever.start();
}

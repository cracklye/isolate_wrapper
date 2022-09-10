import 'dart:isolate';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isolate_wrapper/isolate_wrapper.dart';

const paraemters = {
  "Param1": "This is the param 1",
  "Param2": 2,
};
// Use cases:
// Run once in a separate thread
// Run continually in the background and send it messages to process..

void main() {
  group("isolateManagerTest", () {
    test('returns result successully in init', () async {
      MultiIsolateManager mgr = MultiIsolateManager();
      Stream stream = mgr.getUpdateStream();

      String id = await mgr.run(handleSendResultInit);
      print("completed run");
      await Future.delayed(const Duration(seconds: 5));

      expect(
          stream,
          emitsInOrder([
            [IsolateInfo(id)],
            [IsolateInfo(id)],
            [IsolateInfo(id)],
            [IsolateInfo(id)],
            [IsolateInfo(id)],
            [IsolateInfo(id)],
            [IsolateInfo(id)],
            [IsolateInfo(id)],
            [IsolateInfo(id)],
          ]));
    }); 
    
     test('returns multiple  successully in init', () async {
      MultiIsolateManager mgr = MultiIsolateManager();
      Stream stream = mgr.getUpdateStream();

      String id = await mgr.run(handleSendResultInit);
      String id2 = await mgr.run(handleSendResultInit);
      String id3 = await mgr.run(handleSendResultInit);

      print("completed run");
      await Future.delayed(const Duration(seconds: 5));

      expect(
          stream,
          emitsInOrder([
            [IsolateInfo(id)],
            [IsolateInfo(id)],
            [IsolateInfo(id)],
            [IsolateInfo(id)],
            [IsolateInfo(id)],
            [IsolateInfo(id)],
            [IsolateInfo(id)],
            [IsolateInfo(id)],
            [IsolateInfo(id)],
          ]));
    });
  });
}

void handleSendResultInit(SendPort sendPort) async {
  var reciever = IsolateWrapperReciever(sendPort,
      onInit: (dynamic message, reciever) async {
    reciever.sendProgress("Have initialised", 2);
    for (int i = 2; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      reciever.sendProgress("Updated process to stage $i", i * 10);
    }
  }, onMessage: (msg, rcv) async {
    rcv.sendProgress("Have Recieved message, about to start long process", 10);

    for (int i = 2; i < 10; i++) {
      await Future.delayed(const Duration(seconds: 2));
      print("Sending progress");
      rcv.sendProgress("Updated process to stage $i", i * 10);
    }

    rcv.sendProgress("Cleaning up process", 90);
  });
  await reciever.start();
}

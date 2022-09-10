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
  group('constructor', () {
    test('ID Gets generated', () async {
      var isolate = IsolateWrapper(handleEchoWaitForInit);
      expect(isolate.id, isNotNull);
      //print(isolate.id);
    });
    test('Gets created without description', () async {
      var isolate = IsolateWrapper(handleEchoWaitForInit);
      expect(isolate.id, isNotNull);
      expect(isolate.description, isNull);

      //print(isolate.id);
    });

    test('Gets created with description', () async {
      var isolate = IsolateWrapper(handleEchoWaitForInit,
          description: "A Test Description");
      expect(isolate.id, isNotNull);
      expect(isolate.description, "A Test Description");

      //print(isolate.id);
    });
  });
  group('run', () {
    test('adds one to input values', () async {
      var isolate = IsolateWrapper(
        handleEchoWaitForInit,
        handleProgress: (message) => print('TEST: handle message($message)'),
        handleResult: (message) => print('TEST: handle result($message)'),
        handleError: (message) => print('TEST: handle error($message)'),
      );

      await isolate.run(paraemters);

      //We want to run for a while
      for (int i = 0; i < 2; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await isolate.stop();
    });

    test('continue recieving messages after error', () async {
      int messageCount = 0;
      int resultCount = 0;
      int errorCount = 0;

      var isolate = IsolateWrapper(
        handleEchoWithError,
        handleProgress: (message) {
          print('TEST: handle message($message)');
          messageCount += 1;
        },
        handleResult: (message) {
          print('TEST: handle result($message)');
          resultCount += 1;
        },
        handleError: (message) {
          print('TEST: handle error($message)');
          errorCount += 1;
        },
      );

      await isolate.run(paraemters);

      //We want to run for a while
      for (int i = 0; i < 2; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      expect(messageCount, 1);
      expect(resultCount, 1);
      expect(errorCount, 1);

      await isolate.stop();
    });

    test('reciever gets mutliple messages', () async {
      int messageCount = 0;
      int resultCount = 0;
      int errorCount = 0;

      var isolate = IsolateWrapper(
        handleEcho,
        handleProgress: (message) {
          print('TEST: handle message($message)');
          messageCount += 1;
        },
        handleResult: (message) {
          print('TEST: handle result($message)');
          resultCount += 1;
        },
        handleError: (message) {
          print('TEST: handle error($message)');

          errorCount += 1;
        },
      );

      await isolate.run(paraemters);

      //We want to run for a while
      for (int i = 0; i < 5; i++) {
        await isolate.sendMessage("This is the message");
        await Future.delayed(const Duration(milliseconds: 100));
      }

      expect(messageCount, 6);
      expect(resultCount, 0);
      expect(errorCount, 0);

      await isolate.stop();
    });
    test('reciever gets mutliple results', () async {
      int resultCount = 0;
      var isolate = IsolateWrapper(
        handleEchoMultipleResults,
        handleResult: (message) {
          resultCount += 1;
        },
      );

      await isolate.run();

      //We want to run for a while
      for (int i = 0; i < 5; i++) {
        await isolate.sendMessage("This is the message");
        await Future.delayed(const Duration(milliseconds: 100));
      }

      expect(resultCount, 6);
      await isolate.stop();
    });
  });
  group("runForResult", () {
    test('returns result successully in init', () async {
      var isolate = IsolateWrapper<String>(handleSendResultInit);

      String? res = await isolate.runForResult();
      expect(res, "Result1");
    });
    test('returns error successully in init', () async {
      var isolate = IsolateWrapper<String>(handleSendErrorInit);

      try {
        String? res = await isolate.runForResult();
        expect(false, true);
      } catch (ex) {
        //Success.
        print(ex.toString());
        expect(ex.toString(), "Exception: Error1");
      }
    });

    test('fails when no init is provided with run for result....', () async {
      var isolate = IsolateWrapper<String>(handleSendErrorMessage);

      try {
        String? res = await isolate.runForResult();
        expect(false, true);
      } catch (e) {
        //Success.
        print(e);
        expect(e.toString(), "Exception: RunOnce=True and no init set");
      }
    });
    test('fails when init and onMessage is provided with run for result....',
        () async {
      var isolate = IsolateWrapper<String>(handleEchoWaitForInit);
      try {
        String? res = await isolate.runForResult();
        expect(false, true);
      } catch (e) {
        //Success.
        print(e);
        expect(e.toString(),
            "Exception: RunOnce=True and onMessage hasbeen set, this won't be run");
      }
    });

    test('Stops on result', () async {
      var isolate = IsolateWrapper<String>(handleSendResultMultipleTimes);
      
      expect(await isolate.runForResult(), "Result1");
      expect(isolate.isComplete, true);
      expect(isolate.isRunning, false);
    });
  });



}

void handleSendResultMultipleTimes(SendPort sendPort) async {
  var reciever = IsolateWrapperReciever(sendPort,
      onInit: (dynamic message, reciever) async {
    reciever.sendResult("Result1");
    reciever.sendResult("Result2");
  });
  await reciever.start();
}

void handleSendResultInit(SendPort sendPort) async {
  var reciever = IsolateWrapperReciever(sendPort,
      onInit: (dynamic message, reciever) async {
    reciever.sendResult("Result1");
  });
  await reciever.start();
}

void handleSendResultMessage(SendPort sendPort) async {
  var reciever = IsolateWrapperReciever(sendPort,
      onMessage: (dynamic message, reciever) async {
    reciever.sendResult("Result2");
  });
  await reciever.start();
}

void handleSendErrorInit(SendPort sendPort) async {
  var reciever = IsolateWrapperReciever(sendPort,
      onInit: (dynamic message, reciever) async {
    reciever.sendError("Error1");
  });
  await reciever.start();
}

void handleSendErrorMessage(SendPort sendPort) async {
  var reciever = IsolateWrapperReciever(sendPort,
      onMessage: (dynamic message, reciever) async {
    reciever.sendError("Error2");
  });
  await reciever.start();
}

void handleEchoWaitForInit(SendPort sendPort) async {
  var reciever = IsolateWrapperReciever(
    sendPort,
    onMessage: (dynamic message, reciever) async {
      print("handleEchoWaitForInit: Message $message");
      reciever.sendProgress(message);
    },
    onInit: (parameters, reciever) async {
      print("handleEchoWaitForInit: Parameters recieved");
    },
  );
  await reciever.start();

  reciever.sendProgress("handleEcho => Sending message");
}

void handleEchoDontWaitForInit(SendPort sendPort) async {
  var reciever =
      IsolateWrapperReciever(sendPort, onMessage: (parameters, recv) async {
    print("handleEcho: Parameters recieved");
  }, onInit: (dynamic message, recv) async {
    print("handleEcho: Message $message");
    recv.sendProgress(message);
  });
  await reciever.start(false);
  reciever.sendProgress("handleEcho => Sending message");
}

void handleEchoWithError(SendPort sendPort) async {
  var reciever = IsolateWrapperReciever(sendPort,
      onMessage: (msg, recv) async => print("Message Recieved$msg"),
      onInit: (parameters, recv) async {
        print("<handleEchoWithError>: Message Recieved");
        recv.sendError("<handleEchoWithError> Error Returned");
        recv.sendProgress("<handleEchoWithError> Message returned", 50);
        recv.sendResult("<handleEchoWithError> Result Returned");
      });
  await reciever.start();
}

void handleEchoMultipleResults(SendPort sendPort) async {
  var reciever = IsolateWrapperReciever(sendPort,
      onMessage: (msg, recv) async =>
          recv.sendResult("<handleEchoMultipleResults> Result Returned"),
      onInit: (parameters, recv) async {
        recv.sendResult("<handleEchoMultipleResults> Result Returned");
      });
  await reciever.start();
}

void handleEcho(SendPort sendPort) async {
  int count = 0;

  var reciever =
      IsolateWrapperReciever(sendPort, onMessage: (message, recv) async {
    print("handleEcho: Parameters recieved");
    count += 1;
    recv.sendProgress(message, count);
  }, onInit: (dynamic message, recv) async {
    print("handleEcho: init");
  });
  await reciever.start();
  reciever.sendProgress("handleEcho => Sending message");
}

import 'dart:isolate';

import 'package:flutter/widgets.dart';
import 'package:isolate_wrapper/isolate_wrapper.dart';

class IsolateWrapper<T> {
  /// this function is the function that will run within the
  /// isolate.  The sendPort can be used to send progress IsolateMesages: either IsolateError, IsolateResult or IsolateProgress.
  final Function(SendPort) processFunction;
  final String? description;

  final Function(IsolateProgress)? handleProgress;
  final Function(T)? handleResult;
  final Function(IsolateError)? handleError;
  final Function()? handleComplete;
  final bool runOnce;

  IsolateWrapper(this.processFunction,
      {this.handleProgress,
      this.handleResult,
      this.handleError,
      this.handleComplete,
      this.runOnce = false,
      String? customId,
      this.description})
      : id = customId ?? UniqueKey().toString();

  ReceivePort? _receiveFromPort;
  //SendPort sendThis;

  ReceivePort? _receiveFromRemote;
  SendPort? _sendToRemote;

  Isolate? _isolate;

  bool isComplete = false;

  final String id;

  /// configures the initial ports that are required.

  // Future setup() async {

  // }

  Future<void> run([Map<String, Object> parameters = const {}]) async {
    await _run(
        handleError: handleError,
        handleProgress: handleProgress,
        handleResult: handleResult,
        parameters: parameters,
        runOnce: runOnce);
  }

  Future _run(
      {bool runOnce = false,
      Function(IsolateProgress)? handleProgress,
      Function(T)? handleResult,
      Function(IsolateError)? handleError,
      Map<String, Object> parameters = const {}}) async {
    /// Where I listen to the message from Mike's port
    _receiveFromPort = ReceivePort();

    /// Spawn an isolate, passing my receivePort sendPort
    _isolate = await Isolate.spawn<SendPort>(
        processFunction, _receiveFromPort!.sendPort);

    /// Mike sends a senderPort for me to enable me to send him a message via his sendPort.
    /// I receive Mike's senderPort via my receivePort
    _sendToRemote = await _receiveFromPort!.first;

    /// I set up another receivePort to receive Mike's response.
    _receiveFromRemote = ReceivePort();

    /// I send Mike a message using mikeSendPort. I send him a list,
    /// which includes my message, preferred type of coffee, and finally
    /// a sendPort from mikeResponseReceivePort that enables Mike to send a message back to me.
    _sendToRemote!
        .send(RecieverInit(_receiveFromRemote!.sendPort, runOnce, parameters));

    /// I get Mike's response by listening to mikeResponseReceivePort
    _receiveFromRemote!.listen((message) {
      if (message is! IsolateMessage && message is! T) {
        stop();
        throw Exception("message is not a valid result type $message");
      }
      if (message is IsolateProgress) {
        if (handleProgress != null) {
          handleProgress(message);
        }
      } else if (message is IsolateError) {
        if (handleError != null) {
          handleError(message);
        }
        if (runOnce) {
          isComplete = true;
          stop();
        }
      } else {
        if (handleResult != null) {
          handleResult(message);
        }
        if (runOnce) {
          isComplete = true;
          stop();
        }
      }
    });
  }

  bool get isRunning {
    return _isolate != null;
  }

  Future<void> sendMessage(String message) async {
    _sendToRemote!.send(message);
  }

  Future<T?> runForResult({Map<String, Object> parameters = const {}}) async {
    T? rtn;
    Object? exception;

    await _run(
        runOnce: true,
        handleProgress: handleProgress,
        handleResult: (res) => rtn = res,
        handleError: (err) => exception = err.message,
        parameters: parameters);

    while (!isComplete) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (exception != null) throw Exception(exception);

    return rtn;
  }

  Future stop() async {
    if (handleComplete != null) {
      handleComplete!();
    }
    if (_receiveFromRemote != null) {
      _receiveFromRemote!.close();
    }
    if (_isolate != null) {
      _isolate!.kill();
      _isolate = null;
    }
  }
}

class RecieverInit {
  final SendPort sendPort;
  final bool singleRun;

  final Map<String, Object> parameters;

  RecieverInit(this.sendPort, this.singleRun, [this.parameters = const {}]);
}

class RecieverStop {}

class IsolateWrapperReciever {
  SendPort _sendPortToMe;

  Future<void> Function(RecieverInit, IsolateWrapperReciever)? onInit;

  Future<void> Function(dynamic, IsolateWrapperReciever)? onMessage;

  SendPort? _sendPortToRemote;

  Map<String, Object>? parameters;

  bool _singleRun = false;

  IsolateWrapperReciever(
    this._sendPortToMe, {
    this.onMessage,
    this.onInit,
  });

  Future<void> start([bool waitForInit = true]) async {
    /// Set up a receiver port for Mike
    ReceivePort receivePort = ReceivePort();

    /// Send Mike receivePort sendPort via mySendPort
    _sendPortToMe.send(receivePort.sendPort);

    receivePort.listen((message) async {
      if (message is RecieverInit) {
        _sendPortToRemote = message.sendPort;
        _singleRun = message.singleRun;

        if (_singleRun && onInit == null) {
          sendError("RunOnce=True and no init set");
        } else if (_singleRun && onMessage != null) {
          sendError(
              "RunOnce=True and onMessage hasbeen set, this won't be run");
        }
        if (onInit != null) {
          await onInit!(message, this);
        }
      } else {
        if (onMessage != null) {
          await onMessage!(message, this);
        }
      }
    });

    if (waitForInit) {
      while (_sendPortToRemote == null) {
        //Wait....
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
  }

  void sendProgress(String message, {int progress = 0, dynamic value}) {
    if (_sendPortToRemote != null) {
      _sendPortToRemote!
          .send(IsolateProgress(message, progress: progress, value: value));
    } else {
      throw Exception("Unable to send message as the sendPortToRemote is null");
    }
  }

  void sendError(String message, [Object? exception]) {
    if (_sendPortToRemote != null) {
      _sendPortToRemote!.send(IsolateError(message, exception));
    } else {
      throw Exception("Unable to send message as the sendPortToRemote is null");
    }
  }

  void sendResult(Object result, [Object? exception]) {
    if (_sendPortToRemote != null) {
      _sendPortToRemote!.send(result);
    } else {
      throw Exception("Unable to send message as the sendPortToRemote is null");
    }
  }
}

import 'dart:isolate';

import 'package:isolate_wrapper/isolate_wrapper.dart';

class MultiIsolateManager {
  // List<IsolateWrapper> isolates = [];

  Stream<List<IsolateInfo>> getUpdateStream() {
    return Stream.empty();
  }

  Future<void> run<T>(IsolateWrapper isolate,
      {Function(IsolateProgress)? handleProgress,
      Function(T)? handleResult,
      Function(IsolateError)? handleError,
      Map<String, Object> parameters = const {}}) async {
    // isolates.add(isolate);
    isolate.setup();
    return await isolate.run(
        handleError: (err) {
          _doHandleError(isolate, err);
          if (handleError != null) {
            handleError(err);
          }
        },
        handleProgress: (progress) {
          _doHandleProgress(isolate, progress);
          if (handleProgress != null) {
            handleProgress(progress);
          }
        },
        handleResult: (progress) {
          _doHandleResult<T>(isolate, progress);
          if (handleResult != null) {
            handleResult(progress);
          }
        },
        parameters: parameters);
  }

  Future<T> runForResult<T>(IsolateWrapper isolate,
      {Function(IsolateProgress)? handleProgress,
      Map<String, Object> parameters = const {}}) async {
    // isolates.add(isolate);
    isolate.setup();
    return await isolate.runForResult(
        handleProgress: (progress) {
          _doHandleProgress(isolate, progress);
          if (handleProgress != null) {
            handleProgress(progress);
          }
        },
        parameters: parameters);
  }

  void _doHandleError(IsolateWrapper isolate, IsolateError error) {}
  void _doHandleProgress(IsolateWrapper isolate, IsolateProgress progress) {}
  void _doHandleResult<T>(IsolateWrapper isolate, T result) {}

  void remove(IsolateWrapper isolate) {
    _refreshStream();
  }

  void stop(String id) {}

  void _refreshStream() {}
}

class IsolateInfo {
  final String id;
  final int progress;
  final String progressMessage;
  final String description;
  final bool isComplete;

  IsolateInfo(this.id, this.description, this.progressMessage, this.progress,
      this.isComplete);
}
